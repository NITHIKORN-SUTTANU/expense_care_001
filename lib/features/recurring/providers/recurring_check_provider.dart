import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/recurring_repository.dart';
import '../domain/models/recurring_expense_model.dart';

// ── Date helpers ──────────────────────────────────────────────────────────────

DateTime _nextDue(String frequency, DateTime base) => switch (frequency) {
      'daily' => base.add(const Duration(days: 1)),
      'weekly' => base.add(const Duration(days: 7)),
      'monthly' => _addMonths(base, 1),
      'yearly' => _addMonths(base, 12),
      _ => base,
    };

/// Advances [base] by [months], clamping the day to the last valid day of
/// the target month (e.g. Jan 31 + 1 month → Feb 28/29, not Mar 2/3).
DateTime _addMonths(DateTime base, int months) {
  final totalMonth = base.month - 1 + months;
  final year = base.year + totalMonth ~/ 12;
  final month = totalMonth % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, base.day.clamp(1, lastDay));
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Processes due recurring expenses and writes them to the expenses collection.
///
/// Kept alive by [MainShell] watching [recurringCheckProvider] so the check
/// runs for the entire shell session — not just when HomeScreen is mounted.
class RecurringCheckNotifier extends Notifier<void> {
  bool _running = false;

  @override
  void build() {
    // Re-run whenever auth resolves (handles cold-start and sign-in)
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    if (uid != null) _run(uid);

    // Re-run when the recurring list changes (e.g. user just added one)
    ref.listen<AsyncValue<List<RecurringExpenseModel>>>(
      recurringProvider,
      (_, next) {
        next.whenData((_) {
          final currentUid = ref.read(authStateProvider).valueOrNull?.uid;
          if (currentUid != null) _run(currentUid);
        });
      },
    );
  }

  Future<void> _run(String uid) async {
    if (_running) return;
    _running = true;
    try {
      final now = DateTime.now();

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recurring')
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      bool hasWork = false;

      // Firestore allows 500 operations per batch. We reserve one slot per
      // recurring item for the nextDueDate update, so the expense writes are
      // capped to (490 − itemCount). This prevents silent batch-commit failures
      // when a recurring item has many missed occurrences (e.g. daily × years).
      const kBatchLimit = 490;
      int opsUsed = 0;

      for (final doc in snap.docs) {
        final item = RecurringExpenseModel.fromMap(doc.data(), doc.id);
        var due = item.nextDueDate;

        if (due.isAfter(now)) continue;
        // Reserve 1 op for the nextDueDate update below.
        if (opsUsed >= kBatchLimit - 1) continue;

        while (!due.isAfter(now) && opsUsed < kBatchLimit - 1) {
          final expRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('expenses')
              .doc('${item.id}_${due.millisecondsSinceEpoch}');

          batch.set(
            expRef,
            {
              'userId': uid,
              'amount': item.amount,
              'currency': item.currency,
              'amountInBaseCurrency': item.amount,
              'categoryId': item.categoryId,
              'note': item.note ?? item.name,
              // Use now (processing time) not due (midnight) so the home screen
              // shows "Just now" instead of "Xh ago" for today's occurrences.
              // The document ID is still based on due for deduplication.
              'date': (due.year == now.year &&
                      due.month == now.month &&
                      due.day == now.day)
                  ? now.toIso8601String()
                  : due.toIso8601String(),
              'isRecurring': true,
              'recurringId': item.id,
              'goalId': null,
              'receiptBase64': null,
              'syncedToFirestore': true,
              'createdAt': now.toIso8601String(),
            },
            SetOptions(merge: false),
          );

          due = _nextDue(item.frequency, due);
          hasWork = true;
          opsUsed++;
        }

        batch.update(doc.reference, {'nextDueDate': due.toIso8601String()});
        opsUsed++;
      }

      if (hasWork) await batch.commit();
    } catch (_) {
      // Allow retry on next trigger
    } finally {
      _running = false;
    }
  }
}

final recurringCheckProvider = NotifierProvider<RecurringCheckNotifier, void>(
  RecurringCheckNotifier.new,
);
