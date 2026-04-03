import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/recurring_expense_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/constants/firestore_constants.dart';

final recurringProvider = StreamProvider<List<RecurringExpenseModel>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.recurring)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => RecurringExpenseModel.fromMap(d.data(), d.id))
          .toList());
});
