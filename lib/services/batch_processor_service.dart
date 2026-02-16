
import 'dart:async';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spawnpk_market_dashboard/providers/app_providers.dart';
import '../models/item.dart';
import '../models/trade.dart';
import '../models/hot_item.dart';
import '../models/top_trader.dart';
import 'api_service.dart';


final batchProcessorProvider = Provider<BatchProcessor>((ref) {
  return BatchProcessor(ref.read(apiServiceProvider));
});

class BatchProcessor {
  final ApiService _api;
  final _progressController = StreamController<ProcessingProgress>.broadcast();
  final _resultsController = StreamController<ProcessingResults>.broadcast();
  
  bool _isProcessing = false;
  CancelToken? _cancelToken;

  BatchProcessor(this._api);


  Stream<ProcessingProgress> get progressStream => _progressController.stream;
  Stream<ProcessingResults> get resultsStream => _resultsController.stream;
  
  bool get isProcessing => _isProcessing;


  void cancel() {
    _cancelToken?.cancel();
    _isProcessing = false;
  }


  Future<void> processAllItems({
    required List<Item> items,
    required Function(HotItem) onHotItemFound,
    required Function(TopTrader) onTopTraderFound,
    required Function(ProcessingProgress) onProgress,
  }) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _cancelToken = CancelToken();
    
    final totalItems = items.length;
    final traderStats = <String, TraderStats>{};
    final itemAnalytics = <String, ItemAnalytics>{};
    

    const batchSize = 5;
    var processedCount = 0;
    
    for (var i = 0; i < items.length; i += batchSize) {
      if (_cancelToken!.isCancelled) break;
      
      final batch = items.skip(i).take(batchSize).toList();
      

      await Future.wait(batch.map((item) async {
        try {
          final trades = await _api.fetchTradesForItem(item.searchName);
          

          itemAnalytics[item.displayName] = _analyzeItem(item, trades.trades);
          

          _updateTraderStats(traderStats, trades.trades);
          

          final hotItem = _checkIfHot(item.displayName, itemAnalytics[item.displayName]!);
          if (hotItem != null) {
            onHotItemFound(hotItem);
          }
          
          processedCount++;
          

          final progress = ProcessingProgress(
            processedItems: processedCount,
            totalItems: totalItems,
            currentItem: item.displayName,
            percentage: (processedCount / totalItems * 100).round(),
          );
          
          onProgress(progress);
          _progressController.add(progress);
          
        } catch (e) {
          print('Error processing ${item.displayName}: $e');
        }
      }));
      

      await Future.delayed(const Duration(milliseconds: 10));
    }
    

    if (!_cancelToken!.isCancelled) {
      final topTraders = _calculateTopTraders(traderStats);
      for (var trader in topTraders) {
        onTopTraderFound(trader);
      }
      
      _resultsController.add(ProcessingResults(
        hotItems: itemAnalytics.values
            .where((a) => a.isHot)
            .map((a) => a.toHotItem())
            .toList(),
        topTraders: topTraders,
      ));
    }
    
    _isProcessing = false;
  }

  ItemAnalytics _analyzeItem(Item item, List<Trade> trades) {
    if (trades.length < 5) return ItemAnalytics(item: item, isHot: false);
    
    final now = DateTime.now();
    final recentTrades = trades.where((t) => 
      now.difference(t.timestamp).inHours < 1
    ).toList();
    
    final historicalTrades = trades.where((t) => 
      now.difference(t.timestamp).inHours >= 1 &&
      now.difference(t.timestamp).inDays < 7
    ).toList();
    
    if (historicalTrades.isEmpty) return ItemAnalytics(item: item, isHot: false);
    

    final avgPrice = historicalTrades.map((t) => t.effectivePrice).reduce((a, b) => a + b) / historicalTrades.length;
    final recentAvgPrice = recentTrades.isNotEmpty 
        ? recentTrades.map((t) => t.effectivePrice).reduce((a, b) => a + b) / recentTrades.length
        : avgPrice;
    
    final priceChangePercent = ((recentAvgPrice - avgPrice) / avgPrice) * 100;
    

    final avgHourlyVolume = historicalTrades.fold(0, (sum, t) => sum + t.quantity) / 
        historicalTrades.length;
    final recentVolume = recentTrades.fold(0, (sum, t) => sum + t.quantity);
    final volumeSurge = avgHourlyVolume > 0 ? recentVolume / avgHourlyVolume : 0;
    
    final isHot = priceChangePercent.abs() > 5 || volumeSurge > 2;
    
    return ItemAnalytics(
      item: item,
      isHot: isHot,
      currentPrice: recentAvgPrice,
      priceChangePercent: priceChangePercent,
      volumeSurge: volumeSurge,
      avgVolume: avgHourlyVolume.round(),
      lastTradeTime: recentTrades.isNotEmpty ? recentTrades.first.timestamp : null,
      tradeCount: recentTrades.length,
    );
  }

  HotItem? _checkIfHot(String itemName, ItemAnalytics analytics) {
    if (!analytics.isHot) return null;
    
    return HotItem(
      itemName: itemName,
      currentPrice: analytics.currentPrice ?? 0,
      priceChangePercent: analytics.priceChangePercent ?? 0,
      volumeSurge: analytics.volumeSurge ?? 0,
      avgVolume: analytics.avgVolume ?? 0,
      lastTradeTime: analytics.lastTradeTime ?? DateTime.now(),
      tradeCount: analytics.tradeCount ?? 0,
    );
  }

  void _updateTraderStats(Map<String, TraderStats> stats, List<Trade> trades) {
    for (final trade in trades) {

      if (trade.buyer.isNotEmpty) {
        stats.putIfAbsent(trade.buyer, () => TraderStats());
        stats[trade.buyer]!.addTrade(trade, isBuyer: true);
      }
      

      if (trade.seller.isNotEmpty) {
        stats.putIfAbsent(trade.seller, () => TraderStats());
        stats[trade.seller]!.addTrade(trade, isBuyer: false);
      }
    }
  }

  List<TopTrader> _calculateTopTraders(Map<String, TraderStats> stats) {
    final traders = stats.entries.map((e) {
      final s = e.value;
      return TopTrader(
        rank: 0, // Will set after sorting
        username: e.key,
        totalVolume: s.totalVolume,
        tradeCount: s.tradeCount,
        avgTradeValue: s.tradeCount > 0 ? s.totalVolume / s.tradeCount : 0,
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
    
    return traders.take(100).toList(); // Top 100 traders
  }
}


class ProcessingProgress {
  final int processedItems;
  final int totalItems;
  final String currentItem;
  final int percentage;
  
  ProcessingProgress({
    required this.processedItems,
    required this.totalItems,
    required this.currentItem,
    required this.percentage,
  });
}

class ProcessingResults {
  final List<HotItem> hotItems;
  final List<TopTrader> topTraders;
  
  ProcessingResults({
    required this.hotItems,
    required this.topTraders,
  });
}

class ItemAnalytics {
  final Item item;
  final bool isHot;
  final double? currentPrice;
  final double? priceChangePercent;
  final num? volumeSurge;
  final int? avgVolume;
  final DateTime? lastTradeTime;
  final int? tradeCount;
  
  ItemAnalytics({
    required this.item,
    required this.isHot,
    this.currentPrice,
    this.priceChangePercent,
    this.volumeSurge,
    this.avgVolume,
    this.lastTradeTime,
    this.tradeCount,
  });
  
  HotItem toHotItem() {
    return HotItem(
      itemName: item.displayName,
      currentPrice: currentPrice ?? 0,
      priceChangePercent: priceChangePercent ?? 0,
      volumeSurge: volumeSurge ?? 0,
      avgVolume: avgVolume ?? 0,
      lastTradeTime: lastTradeTime ?? DateTime.now(),
      tradeCount: tradeCount ?? 0,
    );
  }
}

class TraderStats {
  double totalVolume = 0;
  int tradeCount = 0;
  
  void addTrade(Trade trade, {required bool isBuyer}) {
    totalVolume += trade.effectivePrice * trade.quantity;
    tradeCount++;
  }
}

class CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
}