import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../features/expense/data/expense_repository.dart';
import 'user_preferences_provider.dart';

/// Watches daily/weekly/monthly spending totals and fires a local notification
/// the first time spending crosses 80% or 100% of the configured budget limit.
///
/// Uses a simple in-memory [_fired] set so each threshold alert fires at most
/// once per app session. The notifier is kept alive by [MainShell] watching
/// [budgetAlertProvider].
class BudgetAlertNotifier extends Notifier<void> {
  final _fired = <String>{};

  @override
  void build() {
    ref.listen<AsyncValue<double>>(dailyTotalProvider, _onDaily);
    ref.listen<AsyncValue<double>>(weeklyTotalProvider, _onWeekly);
    ref.listen<AsyncValue<double>>(monthlyTotalProvider, _onMonthly);
  }

  void _onDaily(AsyncValue<double>? prev, AsyncValue<double> next) {
    final user = ref.read(userPreferencesNotifierProvider);
    if (user == null || !user.notificationsEnabled) return;
    final budget = user.dailyLimit > 0 ? user.dailyLimit : null;
    _check('daily', prev?.valueOrNull, next.valueOrNull, budget);
  }

  void _onWeekly(AsyncValue<double>? prev, AsyncValue<double> next) {
    final user = ref.read(userPreferencesNotifierProvider);
    if (user == null || !user.notificationsEnabled) return;
    _check('weekly', prev?.valueOrNull, next.valueOrNull, user.weeklyLimit);
  }

  void _onMonthly(AsyncValue<double>? prev, AsyncValue<double> next) {
    final user = ref.read(userPreferencesNotifierProvider);
    if (user == null || !user.notificationsEnabled) return;
    _check('monthly', prev?.valueOrNull, next.valueOrNull, user.monthlyLimit);
  }

  void _check(
    String period,
    double? prevSpent,
    double? spent,
    double? budget,
  ) {
    // Skip first emission (prev is null) and cases without a real budget
    if (prevSpent == null || spent == null || budget == null || budget <= 0) {
      return;
    }

    final prevPct = prevSpent / budget;
    final pct = spent / budget;

    if (pct >= 1.0 && prevPct < 1.0) {
      _fireOnce('${period}_100', _AlertContent(
        title: "You've exceeded your $period budget!",
        body: "You've gone over your $period spending limit.",
      ));
    } else if (pct >= 0.8 && prevPct < 0.8) {
      _fireOnce('${period}_80', _AlertContent(
        title: "80% of your $period budget used",
        body: "You're approaching your $period spending limit.",
      ));
    }
  }

  void _fireOnce(String key, _AlertContent alert) {
    if (_fired.contains(key)) return;
    _fired.add(key);
    NotificationService.instance.show(
      id: _idFor(key),
      title: alert.title,
      body: alert.body,
    );
  }

  int _idFor(String key) => switch (key) {
        'daily_80' => 1001,
        'daily_100' => 1002,
        'weekly_80' => 1003,
        'weekly_100' => 1004,
        'monthly_80' => 1005,
        'monthly_100' => 1006,
        _ => 1000,
      };
}

class _AlertContent {
  const _AlertContent({required this.title, required this.body});
  final String title;
  final String body;
}

final budgetAlertProvider = NotifierProvider<BudgetAlertNotifier, void>(
  BudgetAlertNotifier.new,
);
