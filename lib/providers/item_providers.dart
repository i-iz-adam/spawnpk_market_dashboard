import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'app_providers.dart';


final selectedItemProvider = StateProvider<String?>((ref) => null);


final itemTradesPageProvider = StateProvider<int>((ref) => 1);


final itemTradesProvider = FutureProvider.family<TradesResponse, ({String itemDisplayName, int page})>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final items = await ref.watch(itemsProvider.future);
  final matches = items.where((e) => e.displayName == params.itemDisplayName).toList();
  final item = matches.isNotEmpty ? matches.first : null;
  final nameForApi = (item != null && item.searchName.isNotEmpty) ? item.searchName : params.itemDisplayName;
  return api.fetchTradesForItem(nameForApi, page: params.page);
});
