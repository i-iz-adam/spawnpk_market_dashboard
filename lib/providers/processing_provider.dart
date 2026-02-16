
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/processing_manager.dart';
import '../models/hot_item.dart';
import '../models/top_trader.dart';
import 'app_providers.dart';


class ProcessingState {
  final bool isProcessing;
  final int processedItems;
  final int totalItems;
  final String currentItem;
  final int percentage;
  final List<HotItem> hotItems;
  final List<TopTrader> topTraders; // Added this line

  ProcessingState({
    this.isProcessing = false,
    this.processedItems = 0,
    this.totalItems = 0,
    this.currentItem = '',
    this.percentage = 0,
    this.hotItems = const [],
    this.topTraders = const [], // Added this line
  });

  ProcessingState copyWith({
    bool? isProcessing,
    int? processedItems,
    int? totalItems,
    String? currentItem,
    int? percentage,
    List<HotItem>? hotItems,
    List<TopTrader>? topTraders, // Added this line
  }) {
    return ProcessingState(
      isProcessing: isProcessing ?? this.isProcessing,
      processedItems: processedItems ?? this.processedItems,
      totalItems: totalItems ?? this.totalItems,
      currentItem: currentItem ?? this.currentItem,
      percentage: percentage ?? this.percentage,
      hotItems: hotItems ?? this.hotItems,
      topTraders: topTraders ?? this.topTraders, // Added this line
    );
  }
}


class ProcessingNotifier extends StateNotifier<ProcessingState> {
  ProcessingNotifier() : super(ProcessingState());

  void startProcessing(int totalItems) {
    print('🎬 Processing started: $totalItems items');
    state = ProcessingState(
      isProcessing: true,
      totalItems: totalItems,
      processedItems: 0,
      currentItem: 'Starting...',
      percentage: 0,
      hotItems: [],
      topTraders: [], // Added this line
    );
  }

  void updateProgress(int processed, int total, String currentItem) {
    final percentage = total > 0 ? (processed / total * 100).round() : 0;

    if (state.processedItems != processed || state.currentItem != currentItem) {
      print('📊 Progress: $processed/$total ($percentage%) - $currentItem');
      state = state.copyWith(
        processedItems: processed,
        currentItem: currentItem,
        percentage: percentage,
      );
    }
  }

  void addHotItem(HotItem item) {
    print('🔥 Hot item added: ${item.itemName}');
    final updated = List<HotItem>.from(state.hotItems)..add(item);


    updated.sort((a, b) {
      final aScore = a.volumeSurge * (1 + a.priceChangePercent.abs() / 100);
      final bScore = b.volumeSurge * (1 + b.priceChangePercent.abs() / 100);
      return bScore.compareTo(aScore);
    });

    state = state.copyWith(hotItems: updated.take(10).toList());
  }


  void setTopTraders(List<TopTrader> traders) {
    print('🏆 Top traders updated: ${traders.length} traders');
    state = state.copyWith(topTraders: traders);
  }

  void finishProcessing() {
    print('✅ Processing finished');
    state = state.copyWith(isProcessing: false);
  }

  void reset() {
    print('🔄 Processing reset');
    state = ProcessingState();
  }
}


final processingStateProvider = StateNotifierProvider<ProcessingNotifier, ProcessingState>((ref) {
  return ProcessingNotifier();
});

final processingControllerProvider = Provider((ref) {
  final notifier = ref.read(processingStateProvider.notifier);
  final manager = ref.read(processingManagerProvider);

  return ProcessingController(
    notifier: notifier,
    manager: manager,
    ref: ref,
  );
});

class ProcessingController {
  final ProcessingNotifier notifier;
  final ProcessingManager manager;
  final Ref ref;

  ProcessingController({
    required this.notifier,
    required this.manager,
    required this.ref,
  }) {

    manager.progressStream.listen((progress) {
      notifier.updateProgress(
        progress['processed'] as int,
        progress['total'] as int,
        progress['current'] as String,
      );
    });

    manager.hotItemsStream.listen((hotItem) {
      notifier.addHotItem(hotItem);
    });


    manager.topTradersStream.listen((traders) {
      notifier.setTopTraders(traders);
    });

    manager.completeStream.listen((_) {
      notifier.finishProcessing();
    });
  }

  Future<void> startProcessing() async {
    if (manager.isProcessing) {
      print('⚠️ Already processing');
      return;
    }

    print('🚀 Controller: Starting processing');


    final items = await ref.read(itemsProvider.future);

    notifier.startProcessing(items.length);
    await manager.startProcessing(items);
  }

  void cancelProcessing() {
    print('🛑 Controller: Cancelling');
    manager.cancel();
    notifier.reset();
  }
}