import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../utils/storage_service.dart';

/// API service instance.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Storage service instance.
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

/// Cached display_name values for autocomplete.
final itemNamesProvider = FutureProvider<List<String>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.fetchItems();
  return response.items.map((e) => e.displayName).toList();
});

/// Tracked usernames from storage.
final trackedUsersProvider = FutureProvider<List<String>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getTrackedUsers();
});

/// Poll interval in seconds.
final pollIntervalProvider = StateProvider<int>((ref) => 60);
