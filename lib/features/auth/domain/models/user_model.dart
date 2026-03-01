class UserModel {
  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.preferredCurrency = 'USD',
    this.dailyLimit = 0.0,
    this.weeklyLimit,
    this.monthlyLimit,
    this.showWeeklyOnHome = false,
    this.showMonthlyOnHome = false,
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String preferredCurrency;
  final double dailyLimit;
  final double? weeklyLimit;
  final double? monthlyLimit;
  final bool showWeeklyOnHome;
  final bool showMonthlyOnHome;
  final String themeMode;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get firstName => displayName.split(' ').first;

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      preferredCurrency: data['preferredCurrency'] as String? ?? 'USD',
      dailyLimit: (data['dailyLimit'] as num?)?.toDouble() ?? 0.0,
      weeklyLimit: (data['weeklyLimit'] as num?)?.toDouble(),
      monthlyLimit: (data['monthlyLimit'] as num?)?.toDouble(),
      showWeeklyOnHome: data['showWeeklyOnHome'] as bool? ?? false,
      showMonthlyOnHome: data['showMonthlyOnHome'] as bool? ?? false,
      themeMode: data['themeMode'] as String? ?? 'system',
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'preferredCurrency': preferredCurrency,
        'dailyLimit': dailyLimit,
        'weeklyLimit': weeklyLimit,
        'monthlyLimit': monthlyLimit,
        'showWeeklyOnHome': showWeeklyOnHome,
        'showMonthlyOnHome': showMonthlyOnHome,
        'themeMode': themeMode,
        'notificationsEnabled': notificationsEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? preferredCurrency,
    double? dailyLimit,
    double? weeklyLimit,
    double? monthlyLimit,
    bool? showWeeklyOnHome,
    bool? showMonthlyOnHome,
    String? themeMode,
    bool? notificationsEnabled,
  }) =>
      UserModel(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        preferredCurrency: preferredCurrency ?? this.preferredCurrency,
        dailyLimit: dailyLimit ?? this.dailyLimit,
        weeklyLimit: weeklyLimit ?? this.weeklyLimit,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
        showWeeklyOnHome: showWeeklyOnHome ?? this.showWeeklyOnHome,
        showMonthlyOnHome: showMonthlyOnHome ?? this.showMonthlyOnHome,
        themeMode: themeMode ?? this.themeMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
