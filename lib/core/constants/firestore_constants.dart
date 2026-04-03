/// Firestore collection names and configuration constants
class FirestoreCollections {
  FirestoreCollections._();

  // Collection names
  static const String users = 'users';
  static const String expenses = 'expenses';
  static const String goals = 'goals';
  static const String recurring = 'recurring';
}

/// Firestore configuration values
class FirestoreConfig {
  FirestoreConfig._();

  // Batch operation limits
  static const int maxBatchSize = 500;

  /// Firestore batch limit for recurring expenses (500 - 1 reserved for nextDueDate update)
  static const int batchLimitForRecurring = 490;

  // Pagination
  static const int defaultPageSize = 400;
}
