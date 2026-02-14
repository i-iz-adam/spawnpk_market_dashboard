import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item.dart';
import '../services/api_service.dart';
import '../utils/storage_service.dart';


final apiServiceProvider = Provider<ApiService>((ref) => ApiService());


final storageServiceProvider = Provider<StorageService>((ref) => StorageService());


final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.fetchItems();
  return response.items;
});


final itemNamesProvider = FutureProvider<List<String>>((ref) async {
  final items = await ref.watch(itemsProvider.future);
  return items.map((e) => e.displayName).toList();
});


final trackedUsersProvider = FutureProvider<List<String>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getTrackedUsers();
});


final pollIntervalProvider = StateProvider<int>((ref) => 60);
