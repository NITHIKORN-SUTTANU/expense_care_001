class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.amountInBaseCurrency,
    required this.categoryId,
    this.note,
    this.receiptImageUrl,
    this.receiptBase64,
    required this.date,
    this.isRecurring = false,
    this.recurringId,
    this.goalId,
    this.syncedToFirestore = true,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final String currency;
  final double amountInBaseCurrency;
  final String categoryId;
  final String? note;
  /// Legacy: Firebase Storage download URL. Kept for backward-compat display.
  final String? receiptImageUrl;
  /// Base64-encoded JPEG receipt image stored directly on the document.
  final String? receiptBase64;
  final DateTime date;
  final bool isRecurring;
  final String? recurringId;
  /// Set when this expense was created by adding money to a goal.
  final String? goalId;
  final bool syncedToFirestore;
  final DateTime createdAt;

  factory ExpenseModel.fromMap(Map<String, dynamic> data, String id) {
    return ExpenseModel(
      id: id,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      amountInBaseCurrency: (data['amountInBaseCurrency'] as num).toDouble(),
      categoryId: data['categoryId'] as String,
      note: data['note'] as String?,
      receiptImageUrl: data['receiptImageUrl'] as String?,
      receiptBase64: data['receiptBase64'] as String?,
      date: DateTime.parse(data['date'] as String).toLocal(),
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringId: data['recurringId'] as String?,
      goalId: data['goalId'] as String?,
      syncedToFirestore: true,
      createdAt: DateTime.parse(data['createdAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'amountInBaseCurrency': amountInBaseCurrency,
        'categoryId': categoryId,
        'note': note,
        'receiptImageUrl': receiptImageUrl,
        'receiptBase64': receiptBase64,
        'date': date.toIso8601String(),
        'isRecurring': isRecurring,
        'recurringId': recurringId,
        'goalId': goalId,
        'createdAt': createdAt.toIso8601String(),
      };

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? currency,
    double? amountInBaseCurrency,
    String? categoryId,
    String? note,
    String? receiptImageUrl,
    String? receiptBase64,
    // Set true to explicitly wipe both receipt fields (remove receipt).
    bool clearReceipt = false,
    DateTime? date,
    bool? isRecurring,
    String? recurringId,
    String? goalId,
    bool? syncedToFirestore,
  }) =>
      ExpenseModel(
        id: id ?? this.id,
        userId: userId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        amountInBaseCurrency: amountInBaseCurrency ?? this.amountInBaseCurrency,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        receiptImageUrl:
            clearReceipt ? null : (receiptImageUrl ?? this.receiptImageUrl),
        receiptBase64:
            clearReceipt ? null : (receiptBase64 ?? this.receiptBase64),
        date: date ?? this.date,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringId: recurringId ?? this.recurringId,
        goalId: goalId ?? this.goalId,
        syncedToFirestore: syncedToFirestore ?? this.syncedToFirestore,
        createdAt: createdAt,
      );
}
