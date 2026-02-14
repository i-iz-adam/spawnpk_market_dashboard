import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trades_response.dart';
import 'app_providers.dart';


final selectedUserProvider = StateProvider<String?>((ref) => null);


final userTradesSearchQueryProvider = StateProvider<String>((ref) => '');


final userPurchasesPageProvider = StateProvider<int>((ref) => 1);


final userSalesPageProvider = StateProvider<int>((ref) => 1);


final userTradesProvider = FutureProvider.family<TradesResponse, String>((ref, username) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchTradesForUser(username);
});


final userPurchasesProvider = FutureProvider.family<TradesResponse, String>((ref, username) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchPurchasesForUser(username);
});


final userSalesProvider = FutureProvider.family<TradesResponse, String>((ref, usernameWithUnderscores) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchSalesForUser(usernameWithUnderscores);
});
