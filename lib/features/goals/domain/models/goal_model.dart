class GoalModel {
  const GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    required this.currency,
    this.targetDate,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final String currency;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progress * 100).round();

  bool get justCompleted => savedAmount >= targetAmount && !isCompleted;

  factory GoalModel.fromMap(Map<String, dynamic> data, String id) {
    return GoalModel(
      id: id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      emoji: data['emoji'] as String? ?? '🎯',
      targetAmount: (data['targetAmount'] as num).toDouble(),
      savedAmount: (data['savedAmount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      targetDate: data['targetDate'] != null
          ? DateTime.parse(data['targetDate'] as String)
          : null,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'emoji': emoji,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'currency': currency,
        'targetDate': targetDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  GoalModel copyWith({
    String? name,
    String? emoji,
    double? targetAmount,
    double? savedAmount,
    String? currency,
    DateTime? targetDate,
    bool? isCompleted,
  }) =>
      GoalModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        currency: currency ?? this.currency,
        targetDate: targetDate ?? this.targetDate,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
