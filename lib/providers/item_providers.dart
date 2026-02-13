import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'app_providers.dart';

/// Selected item name for item lookup.
final selectedItemProvider = StateProvider<String?>((ref) => null);

/// Current page for item trades pagination.
final itemTradesPageProvider = StateProvider<int>((ref) => 1);

/// Recent trades for selected item.
final itemTradesProvider = FutureProvider.family<TradesResponse, ({String itemName, int page})>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchTradesForItem(params.itemName, page: params.page);
});
