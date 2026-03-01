import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Exposes the current user's Firestore document as a stream.
/// Delegates to [currentUserProvider] which watches Firebase auth + Firestore.
final userPreferencesProvider = currentUserProvider;

/// Notifier that allows updating user preferences and syncing to Firestore.
class UserPreferencesNotifier extends StateNotifier<UserModel?> {
  UserPreferencesNotifier(this._ref) : super(null);

  final Ref _ref;

  // Called by the provider setup to keep state in sync with the stream.
  void _seed(UserModel? user) => state = user;

  Future<void> updateLimits({
    required double dailyLimit,
    double? weeklyLimit,
    double? monthlyLimit,
    required bool showWeeklyOnHome,
    required bool showMonthlyOnHome,
  }) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(
      dailyLimit: dailyLimit,
      weeklyLimit: weeklyLimit,
      monthlyLimit: monthlyLimit,
      showWeeklyOnHome: showWeeklyOnHome,
      showMonthlyOnHome: showMonthlyOnHome,
    );
    state = updated;
    await _ref.read(authRepositoryProvider).updateUser(updated);
  }

  Future<void> updateCurrency(String currency) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(preferredCurrency: currency);
    state = updated;
    await _ref.read(authRepositoryProvider).updateUser(updated);
  }

  Future<void> updateTheme(String themeMode) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(themeMode: themeMode);
    state = updated;
    await _ref.read(authRepositoryProvider).updateUser(updated);
  }

  Future<void> updateNotifications(bool enabled) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(notificationsEnabled: enabled);
    state = updated;
    await _ref.read(authRepositoryProvider).updateUser(updated);
  }
}

final userPreferencesNotifierProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserModel?>(
  (ref) {
    final notifier = UserPreferencesNotifier(ref);
    // Mirror the stream into the notifier's state.
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (_, next) {
      next.whenData(notifier._seed);
    });
    return notifier;
  },
);
