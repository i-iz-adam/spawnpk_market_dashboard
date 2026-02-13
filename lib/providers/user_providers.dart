import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trades_response.dart';
import 'app_providers.dart';

/// Selected username for user lookup.
final selectedUserProvider = StateProvider<String?>((ref) => null);

/// All trades for selected user.
final userTradesProvider = FutureProvider.family<TradesResponse, String>((ref, username) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchTradesForUser(username);
});

/// Purchases only for selected user.
final userPurchasesProvider = FutureProvider.family<TradesResponse, String>((ref, username) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchPurchasesForUser(username);
});

/// Sales only for selected user. Username must use underscores.
final userSalesProvider = FutureProvider.family<TradesResponse, String>((ref, usernameWithUnderscores) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSalesForUser(usernameWithUnderscores);
});
