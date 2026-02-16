
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spawnpk_market_dashboard/providers/app_providers.dart';
import '../models/item.dart';
import '../models/trade.dart';
import '../models/hot_item.dart';
import '../models/top_trader.dart';
import 'api_service.dart';

class ProcessingManager {
  final ApiService _api;
  bool _isProcessing = false;
  int _processedCount = 0;
  int _totalItems = 0;
  String _currentItem = '';
  final List<HotItem> _hotItems = [];
  final List<TopTrader> _topTraders = [];
  

  final _progressController = StreamController<Map<String, dynamic>>.broadcast();
  final _hotItemsController = StreamController<HotItem>.broadcast();
  final _topTradersController = StreamController<List<TopTrader>>.broadcast(); // Added this
  final _completeController = StreamController<bool>.broadcast();
  
  ProcessingManager(this._api);
  

  Stream<Map<String, dynamic>> get progressStream => _progressController.stream;
  Stream<HotItem> get hotItemsStream => _hotItemsController.stream;
  Stream<List<TopTrader>> get topTradersStream => _topTradersController.stream; // Added this
  Stream<bool> get completeStream => _completeController.stream;
  
  bool get isProcessing => _isProcessing;
  int get processedCount => _processedCount;
  int get totalItems => _totalItems;
  List<HotItem> get hotItems => List.unmodifiable(_hotItems);
  List<TopTrader> get topTraders => List.unmodifiable(_topTraders);
  
  Future<void> startProcessing(List<Item> items) async {
    if (_isProcessing) {
      print('⚠️ Processing already running');
      return;
    }
    
    _isProcessing = true;
    _processedCount = 0;
    _totalItems = items.length;
    _hotItems.clear();
    _topTraders.clear();
    
    print('🎬 STARTING PROCESSING: $_totalItems items');
    

    _sendProgress();
    

    for (var i = 0; i < items.length; i++) {
      if (!_isProcessing) break; // Check if cancelled
      
      final item = items[i];
      _currentItem = item.displayName;
      
      try {
        print('🔍 [${i + 1}/$_totalItems] Processing: ${item.displayName}');
        

        final response = await _api.fetchTradesForItem(item.searchName);
        final trades = response.trades;
        
        print('   ✓ Found ${trades.length} trades');
        

        if (trades.length >= 5) {
          final hotItem = _analyzeItem(item, trades);
          if (hotItem != null) {
            print('   🔥 HOT ITEM FOUND: ${item.displayName}');
            _hotItems.add(hotItem);
            _hotItemsController.add(hotItem);
          }
        }
        

        _updateTraderStats(trades);
        
        _processedCount++;
        _sendProgress();
        

        await Future.delayed(const Duration(milliseconds: 10));
        
      } catch (e) {
        print('   ❌ Error: $e');
        _processedCount++;
        _sendProgress();
      }
    }
    

    final topTraders = _calculateTopTraders();
    _topTradersController.add(topTraders);
    
    print('✅ PROCESSING COMPLETE: $_processedCount/$_totalItems items');
    _isProcessing = false;
    _completeController.add(true);
  }
  
  void _sendProgress() {
    _progressController.add({
      'processed': _processedCount,
      'total': _totalItems,
      'current': _currentItem,
      'percentage': _totalItems > 0 ? (_processedCount / _totalItems * 100).round() : 0,
    });
  }
  
  HotItem? _analyzeItem(Item item, List<Trade> trades) {
    if (trades.length < 5) return null;
    
    final now = DateTime.now();
    final recentTrades = trades.where((t) => 
      now.difference(t.timestamp).inHours < 1
    ).toList();
    
    final historicalTrades = trades.where((t) => 
      now.difference(t.timestamp).inHours >= 1 &&
      now.difference(t.timestamp).inDays < 7
    ).toList();
    
    if (historicalTrades.isEmpty) return null;
    

    final avgPrice = historicalTrades.map((t) => t.effectivePrice).reduce((a, b) => a + b) / historicalTrades.length;
    final recentAvgPrice = recentTrades.isNotEmpty 
        ? recentTrades.map((t) => t.effectivePrice).reduce((a, b) => a + b) / recentTrades.length
        : avgPrice;
    
    final priceChangePercent = ((recentAvgPrice - avgPrice) / avgPrice) * 100;
    

    final avgHourlyVolume = historicalTrades.fold(0, (sum, t) => sum + t.quantity) / 
        historicalTrades.length;
    final recentVolume = recentTrades.fold(0, (sum, t) => sum + t.quantity);
    final volumeSurge = avgHourlyVolume > 0 ? recentVolume / avgHourlyVolume : 0;
    

    if (priceChangePercent.abs() > 5 || volumeSurge > 2) {
      return HotItem(
        itemName: item.displayName,
        currentPrice: recentAvgPrice,
        priceChangePercent: priceChangePercent,
        volumeSurge: volumeSurge,
        avgVolume: avgHourlyVolume.round(),
        lastTradeTime: recentTrades.isNotEmpty ? recentTrades.first.timestamp : DateTime.now(),
        tradeCount: recentTrades.length,
      );
    }
    
    return null;
  }
  

  final Map<String, TraderStats> _traderStats = {};
  
  void _updateTraderStats(List<Trade> trades) {
    for (final trade in trades) {

      if (trade.buyer.isNotEmpty) {
        _traderStats.putIfAbsent(trade.buyer, () => TraderStats());
        _traderStats[trade.buyer]!.addTrade(trade, isBuyer: true);
      }
      

      if (trade.seller.isNotEmpty) {
        _traderStats.putIfAbsent(trade.seller, () => TraderStats());
        _traderStats[trade.seller]!.addTrade(trade, isBuyer: false);
      }
    }
  }
  
  List<TopTrader> _calculateTopTraders() {
    final traders = _traderStats.entries.map((e) {
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
  
  void cancel() {
    print('🛑 CANCELLING PROCESSING');
    _isProcessing = false;
    _completeController.add(false);
  }
  
  void dispose() {
    _progressController.close();
    _hotItemsController.close();
    _topTradersController.close(); // Added this
    _completeController.close();
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


final processingManagerProvider = Provider<ProcessingManager>((ref) {
  final api = ref.read(apiServiceProvider);
  return ProcessingManager(api);
});