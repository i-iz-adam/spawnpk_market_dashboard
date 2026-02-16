
import 'dart:math';
import '../models/hot_item.dart';
import '../models/top_trader.dart';
import '../models/trade.dart';
import 'api_service.dart';

class AnalyticsService {
  AnalyticsService(this._api);
  
  final ApiService _api;
  

  final Map<String, List<Trade>> _tradeCache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  Future<List<Trade>> _getTradesForItem(String itemName, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final cached = _tradeCache[itemName];
    final cachedTime = _cacheTime[itemName];
    
    if (!forceRefresh && cached != null && cachedTime != null && 
        now.difference(cachedTime) < _cacheDuration) {
      return cached;
    }
    
    try {
      final response = await _api.fetchTradesForItem(itemName);
      _tradeCache[itemName] = response.trades;
      _cacheTime[itemName] = now;
      return response.trades;
    } catch (e) {
      return cached ?? [];
    }
  }
  
  Future<List<HotItem>> calculateHotItems() async {

    final itemsResponse = await _api.fetchItems();
    final items = itemsResponse.items;
    
    final hotItems = <HotItem>[];
    
    for (final item in items) { // Analyze top 20 items
      final trades = await _getTradesForItem(item.searchName);
      if (trades.length < 5) continue; // Need enough data
      

      final now = DateTime.now();
      final recentTrades = trades.where((t) => 
        now.difference(t.timestamp).inHours < 1
      ).toList();
      
      if (recentTrades.isEmpty) continue;
      
      final historicalTrades = trades.where((t) => 
        now.difference(t.timestamp).inHours >= 1 &&
        now.difference(t.timestamp).inDays < 7
      ).toList();
      
      if (historicalTrades.isEmpty) continue;
      

      final avgPrice = historicalTrades.map((t) => t.effectivePrice).reduce((a, b) => a + b) / historicalTrades.length;
      final recentAvgPrice = recentTrades.map((t) => t.effectivePrice).reduce((a, b) => a + b) / recentTrades.length;
      
      final priceChangePercent = ((recentAvgPrice - avgPrice) / avgPrice) * 100;
      

      final avgHourlyVolume = historicalTrades.fold(0, (sum, t) => sum + t.quantity) / 
          (historicalTrades.isEmpty ? 1 : historicalTrades.length);
      final recentVolume = recentTrades.fold(0, (sum, t) => sum + t.quantity);
      final volumeSurge = avgHourlyVolume > 0 ? recentVolume / avgHourlyVolume : 0;
      

      if (priceChangePercent.abs() > 5 || volumeSurge > 2) {
        hotItems.add(HotItem(
          itemName: item.displayName,
          currentPrice: recentAvgPrice,
          priceChangePercent: priceChangePercent,
          volumeSurge: volumeSurge,
          avgVolume: avgHourlyVolume.round(),
          lastTradeTime: recentTrades.first.timestamp,
          tradeCount: recentTrades.length,
        ));
      }
    }
    

    hotItems.sort((a, b) {
      final aScore = a.volumeSurge * (1 + a.priceChangePercent.abs() / 100);
      final bScore = b.volumeSurge * (1 + b.priceChangePercent.abs() / 100);
      return bScore.compareTo(aScore);
    });
    
    return hotItems.take(10).toList();
  }
  
  Future<List<TopTrader>> calculateTopTraders() async {
    final items = await _api.fetchItems();
    final traderStats = <String, Map<String, dynamic>>{};
    
    for (final item in items.items.take(10)) {
      final trades = await _getTradesForItem(item.searchName);
      
      for (final trade in trades) {

        if (trade.buyer.isNotEmpty) {
          if (!traderStats.containsKey(trade.buyer)) {
            traderStats[trade.buyer] = {
              'totalVolume': 0.0,
              'tradeCount': 0,
            };
          }
          traderStats[trade.buyer]!['totalVolume'] = 
              (traderStats[trade.buyer]!['totalVolume'] as double) + 
              (trade.effectivePrice * trade.quantity);
          traderStats[trade.buyer]!['tradeCount'] = 
              (traderStats[trade.buyer]!['tradeCount'] as int) + 1;
        }
        

        if (trade.seller.isNotEmpty) {
          if (!traderStats.containsKey(trade.seller)) {
            traderStats[trade.seller] = {
              'totalVolume': 0.0,
              'tradeCount': 0,
            };
          }
          traderStats[trade.seller]!['totalVolume'] = 
              (traderStats[trade.seller]!['totalVolume'] as double) + 
              (trade.effectivePrice * trade.quantity);
          traderStats[trade.seller]!['tradeCount'] = 
              (traderStats[trade.seller]!['tradeCount'] as int) + 1;
        }
      }
    }
    

    final traders = traderStats.entries.map((e) {
      final volume = e.value['totalVolume'] as double;
      final count = e.value['tradeCount'] as int;
      return TopTrader(
        rank: 0, // Will set after sorting
        username: e.key,
        totalVolume: volume,
        tradeCount: count,
        avgTradeValue: count > 0 ? volume / count : 0,
      );
    }).toList();
    
    traders.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
    

    for (var i = 0; i < traders.length; i++) {
      traders[i] = TopTrader(
        rank: i + 1,
        username: traders[i].username,
        totalVolume: traders[i].totalVolume,
        tradeCount: traders[i].tradeCount,
        avgTradeValue: traders[i].avgTradeValue,
      );
    }
    
    return traders.take(10).toList();
  }
  
  Future<Trade?> getLastUserTrade(String username) async {
    try {
      final purchases = await _api.fetchPurchasesForUser(username);
      final sales = await _api.fetchSalesForUser(username.replaceAll(' ', '_'));
      
      final allTrades = [...purchases.trades, ...sales.trades];
      if (allTrades.isEmpty) return null;
      
      allTrades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allTrades.first;
    } catch (e) {
      return null;
    }
  }
  
  void clearCache() {
    _tradeCache.clear();
    _cacheTime.clear();
  }
}