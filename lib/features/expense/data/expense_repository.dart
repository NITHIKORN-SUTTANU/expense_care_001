import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/expense_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/utils/app_date_utils.dart';

class ExpenseRepository {
  ExpenseRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('expenses');

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> add(ExpenseModel expense) =>
      _ref(expense.userId).doc(expense.id).set(expense.toMap());

  Future<void> delete(String uid, String expenseId) =>
      _ref(uid).doc(expenseId).delete();

  Future<void> update(ExpenseModel expense) =>
      _ref(expense.userId).doc(expense.id).update(expense.toMap());

  // ── Read ───────────────────────────────────────────────────────────────────

  Stream<List<ExpenseModel>> watchRecent(String uid, {int limit = 5}) {
    return _ref(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(_toList);
  }

  Stream<List<ExpenseModel>> watchByDateRange(
    String uid,
    DateTime from,
    DateTime to,
  ) {
    return _ref(uid)
        .where('date', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('date', isLessThanOrEqualTo: to.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map(_toList);
  }

  Stream<double> watchDailyTotal(String uid) {
    final now = DateTime.now();
    return _ref(uid)
        .where('date',
            isGreaterThanOrEqualTo:
                AppDateUtils.startOfDay(now).toIso8601String())
        .where('date',
            isLessThanOrEqualTo: AppDateUtils.endOfDay(now).toIso8601String())
        .snapshots()
        .map((snap) => snap.docs.fold<double>(
            0,
            (acc, d) =>
                acc +
                ((d.data()['amountInBaseCurrency'] as num?)?.toDouble() ??
                    0)));
  }

  Stream<double> watchWeeklyTotal(String uid) {
    final now = DateTime.now();
    return _ref(uid)
        .where('date',
            isGreaterThanOrEqualTo:
                AppDateUtils.startOfWeek(now).toIso8601String())
        .where('date',
            isLessThanOrEqualTo: AppDateUtils.endOfDay(now).toIso8601String())
        .snapshots()
        .map((snap) => snap.docs.fold<double>(
            0,
            (acc, d) =>
                acc +
                ((d.data()['amountInBaseCurrency'] as num?)?.toDouble() ??
                    0)));
  }

  Stream<double> watchMonthlyTotal(String uid) {
    final now = DateTime.now();
    return _ref(uid)
        .where('date',
            isGreaterThanOrEqualTo:
                AppDateUtils.startOfMonth(now).toIso8601String())
        .where('date',
            isLessThanOrEqualTo: AppDateUtils.endOfDay(now).toIso8601String())
        .snapshots()
        .map((snap) => snap.docs.fold<double>(
            0,
            (acc, d) =>
                acc +
                ((d.data()['amountInBaseCurrency'] as num?)?.toDouble() ??
                    0)));
  }

  List<ExpenseModel> _toList(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => ExpenseModel.fromMap(d.data(), d.id)).toList();
}

// ── Providers ──────────────────────────────────────────────────────────────────

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (_) => ExpenseRepository(),
);

final recentExpensesProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(expenseRepositoryProvider).watchRecent(uid);
});

final dailyTotalProvider = StreamProvider<double>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0.0);
  return ref.read(expenseRepositoryProvider).watchDailyTotal(uid);
});

final weeklyTotalProvider = StreamProvider<double>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0.0);
  return ref.read(expenseRepositoryProvider).watchWeeklyTotal(uid);
});

final monthlyTotalProvider = StreamProvider<double>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0.0);
  return ref.read(expenseRepositoryProvider).watchMonthlyTotal(uid);
});
