/// Application timing and duration constants
class AppDurations {
  AppDurations._();

  // Splash and initialization
  static const Duration splashDelay = Duration(milliseconds: 1500);

  // UI animations
  static const Duration scrollAnimation = Duration(milliseconds: 300);
  static const Duration buttonAnimation = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 300);

  // Batch operations
  static const Duration uiBatchUpdate = Duration(milliseconds: 30);
}
