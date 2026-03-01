class RecurringExpenseModel {
  const RecurringExpenseModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.note,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final String categoryId;

  /// One of: 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String frequency;

  final DateTime startDate;
  final DateTime nextDueDate;
  final String? note;
  final bool isActive;
  final DateTime createdAt;

  String get frequencyLabel => switch (frequency) {
        'daily' => 'Daily',
        'weekly' => 'Weekly',
        'monthly' => 'Monthly',
        'yearly' => 'Yearly',
        _ => frequency,
      };

  factory RecurringExpenseModel.fromMap(Map<String, dynamic> data, String id) {
    return RecurringExpenseModel(
      id: id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      categoryId: data['categoryId'] as String,
      frequency: data['frequency'] as String,
      startDate: DateTime.parse(data['startDate'] as String),
      nextDueDate: DateTime.parse(data['nextDueDate'] as String),
      note: data['note'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'amount': amount,
        'currency': currency,
        'categoryId': categoryId,
        'frequency': frequency,
        'startDate': startDate.toIso8601String(),
        'nextDueDate': nextDueDate.toIso8601String(),
        'note': note,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  DateTime computeNextDue() {
    final base = nextDueDate;
    return switch (frequency) {
      'daily' => base.add(const Duration(days: 1)),
      'weekly' => base.add(const Duration(days: 7)),
      'monthly' => DateTime(base.year, base.month + 1, base.day),
      'yearly' => DateTime(base.year + 1, base.month, base.day),
      _ => base,
    };
  }
}
