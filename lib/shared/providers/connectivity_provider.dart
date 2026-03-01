import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// True when at least one connectivity type is available (not none).
final isOnlineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityProvider).valueOrNull;
  if (result == null) return true; // Assume online until we know otherwise
  return result.any((r) => r != ConnectivityResult.none);
});
