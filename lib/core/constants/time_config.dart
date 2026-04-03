/// Time-based configuration constants
class TimeGreetings {
  TimeGreetings._();

  // Time thresholds (hours)
  static const int morningThreshold = 12;
  static const int afternoonThreshold = 17;

  // Greeting messages
  static const String morning = 'Good morning';
  static const String afternoon = 'Good afternoon';
  static const String evening = 'Good evening';

  /// Get greeting based on current hour
  static String getGreeting(int hour) {
    if (hour < morningThreshold) return morning;
    if (hour < afternoonThreshold) return afternoon;
    return evening;
  }
}
