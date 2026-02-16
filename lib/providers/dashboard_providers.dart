
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hot_item.dart';
import '../models/top_trader.dart';
import '../models/trade.dart';
import '../services/analytics_service.dart';
import 'app_providers.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AnalyticsService(api);
});


final recentTradesProvider = FutureProvider<List<Trade>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final items = await ref.watch(itemsProvider.future);
  

  final allTrades = <Trade>[];
  for (final item in items) {
    try {
      final response = await api.fetchTradesForItem(item.searchName, page: 1);
      allTrades.addAll(response.trades);
    } catch (e) {

      continue;
    }
  }
  

  allTrades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return allTrades.toList();
});


final hotItemsProvider = FutureProvider<List<HotItem>>((ref) async {
  final analytics = ref.watch(analyticsServiceProvider);
  return analytics.calculateHotItems();
});


final topTradersProvider = FutureProvider<List<TopTrader>>((ref) async {
  final analytics = ref.watch(analyticsServiceProvider);
  return analytics.calculateTopTraders();
});


final trackedUsersWithActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  
  final users = await storage.getTrackedUsers();
  final result = <Map<String, dynamic>>[];
  
  for (final username in users) {
    final lastTrade = await analytics.getLastUserTrade(username);
    result.add({
      'username': username,
      'lastTrade': lastTrade,
      'hasActivity': lastTrade != null,
    });
  }
  

  result.sort((a, b) {
    if (a['lastTrade'] == null) return 1;
    if (b['lastTrade'] == null) return -1;
    return (b['lastTrade'] as Trade).timestamp.compareTo((a['lastTrade'] as Trade).timestamp);
  });
  
  return result;
});


final dashboardRefreshProvider = Provider((ref) {
  return {
    'recentTrades': () => ref.refresh(recentTradesProvider),
    'hotItems': () => ref.refresh(hotItemsProvider),
    'topTraders': () => ref.refresh(topTradersProvider),
    'trackedUsers': () => ref.refresh(trackedUsersWithActivityProvider),
  };
});