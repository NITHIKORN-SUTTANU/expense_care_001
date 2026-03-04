import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/expense/data/expense_repository.dart';
import '../../features/expense/domain/models/expense_model.dart';

/// Shows the canonical type-aware delete confirmation dialog for any expense.
///
/// - **Recurring-generated** → "Delete This Occurrence?" (rule unaffected)
/// - **Savings / goal-linked** → "Delete Savings Entry?" (goal progress drops)
/// - **Regular** → "Delete Expense?"
///
/// Returns [true] if confirmed, [false] if cancelled, [null] if dismissed.
Future<bool?> showExpenseDeleteDialog(
  BuildContext context,
  ExpenseModel expense,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final errorColor = isDark ? AppColors.darkError : AppColors.error;

  final title = expense.isRecurring
      ? 'Delete This Occurrence?'
      : expense.goalId != null
          ? 'Delete Savings Entry?'
          : 'Delete Expense?';

  final body = expense.isRecurring
      ? 'This removes just this one auto-generated entry. '
          'The recurring rule will not be affected.'
      : expense.goalId != null
          ? "This removes the savings record and reduces the linked goal's progress."
          : 'This will permanently remove this expense.';

  return showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Delete',
            style: TextStyle(color: errorColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Deletes [expense] from Firestore via [repo].
///
/// For savings expenses linked to a goal (`expense.goalId != null`), also
/// decrements the goal's `savedAmount` and recalculates `isCompleted`.
///
/// Throws if the primary expense delete fails. Goal-sync errors are suppressed
/// (expense is gone; silent failure avoids confusing UI).
Future<void> deleteExpenseAndSync(
  ExpenseModel expense,
  ExpenseRepository repo,
) async {
  await repo.delete(expense.userId, expense.id);

  if (expense.goalId != null) {
    try {
      final goalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(expense.userId)
          .collection('goals')
          .doc(expense.goalId);
      final snap = await goalRef.get();
      if (snap.exists) {
        final data = snap.data()!;
        final currentSaved = (data['savedAmount'] as num).toDouble();
        final targetAmount = (data['targetAmount'] as num).toDouble();
        final newSaved = (currentSaved - expense.amountInBaseCurrency)
            .clamp(0.0, double.maxFinite);
        await goalRef.update({
          'savedAmount': newSaved,
          'isCompleted': newSaved >= targetAmount,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // Goal sync failed — expense already deleted; suppress.
    }
  }
}
