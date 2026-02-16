
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/notification_provider.dart';
import '../../providers/processing_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_search_bar.dart';
import '../../widgets/hot_items_column.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/quick_actions_column.dart';
import '../../widgets/recent_trades_column.dart';
import '../../widgets/top_traders_section.dart';


final _processingStartedProvider = StateProvider<bool>((ref) => false);

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 400 && !_showScrollTop) {
      setState(() => _showScrollTop = true);
    } else if (_scrollController.offset <= 400 && _showScrollTop) {
      setState(() => _showScrollTop = false);
    }
  }

  Future<void> _initializeData() async {
    print('🚀 Dashboard initializing...');
    

    final hasStarted = ref.read(_processingStartedProvider);
    if (hasStarted) {
      print('⏭️ Processing already started, skipping');
      return;
    }
    
    final processingState = ref.read(processingStateProvider);
    print('📊 Initial processing state: ${processingState.processedItems}/${processingState.totalItems}, isProcessing: ${processingState.isProcessing}');
    
    if (!processingState.isProcessing && processingState.hotItems.isEmpty) {
      print('🔄 Starting background processing...');
      

      ref.read(_processingStartedProvider.notifier).state = true;
      

      await ref.read(processingControllerProvider).startProcessing();
      print('✅ Processing started');
    } else {
      print('⏭️ Processing already running or data exists');
    }
  }

  Future<void> _refreshData() async {
    final controller = ref.read(processingControllerProvider);
    final state = ref.read(processingStateProvider);
    
    if (state.isProcessing) {
      controller.cancelProcessing();

      ref.read(_processingStartedProvider.notifier).state = false;
    } else {

      ref.invalidate(hotItemsProvider);
      ref.invalidate(topTradersProvider);
      ref.invalidate(recentTradesProvider);
      ref.invalidate(trackedUsersWithActivityProvider);
      

      ref.read(_processingStartedProvider.notifier).state = false;
      _initializeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final processingState = ref.watch(processingStateProvider);
    

    ref.listen<ProcessingState>(processingStateProvider, (prev, next) {
      if (prev?.processedItems != next.processedItems || prev?.currentItem != next.currentItem) {
        print('🔔 Processing state changed: ${next.processedItems}/${next.totalItems} (${next.percentage}%) - ${next.currentItem}');
      }
    });
    
    ref.listen(unreadNotificationsProvider, (prev, next) {

    });

    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [

              SliverAppBar(
                expandedHeight: 80,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                      0,
                    ),
                    child: Row(
                      children: [

                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(
                                Icons.show_chart,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'SpawnPK Market',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.xxl),
                        

                        const Expanded(
                          child: GlobalSearchBar(),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        

                        _buildRefreshButton(context, processingState),
                        const SizedBox(width: AppSpacing.sm),
                        

                        const NotificationBell(),
                      ],
                    ),
                  ),
                ),
              ),
              

              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    if (processingState.isProcessing)
                      _buildProcessingBanner(processingState),
                    

                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 900) {

                          return Column(
                            children: const [
                              QuickActionsColumn(),
                              SizedBox(height: AppSpacing.xl),
                              HotItemsColumn(),
                              SizedBox(height: AppSpacing.xl),
                              RecentTradesColumn(),
                            ],
                          );
                        } else {

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(flex: 3, child: QuickActionsColumn()),
                              SizedBox(width: AppSpacing.xl),
                              Expanded(flex: 4, child: HotItemsColumn()),
                              SizedBox(width: AppSpacing.xl),
                              Expanded(flex: 3, child: RecentTradesColumn()),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    

                    const TopTradersSection(),
                    const SizedBox(height: AppSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),
          

          if (_showScrollTop)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.small(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: const Icon(Icons.arrow_upward),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, ProcessingState state) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state.isProcessing 
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (state.isProcessing)
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                value: state.totalItems > 0 
                    ? state.processedItems / state.totalItems 
                    : null,
              ),
            ),
          IconButton(
            icon: Icon(
              state.isProcessing ? Icons.stop : Icons.refresh,
              size: 20,
              color: state.isProcessing ? Colors.blue : AppColors.onSurfaceVariant,
            ),
            onPressed: _refreshData,
            tooltip: state.isProcessing ? 'Stop Processing' : 'Refresh All Data',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingBanner(ProcessingState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing market data: ${state.processedItems}/${state.totalItems} items',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analyzing ${state.currentItem}...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: state.processedItems / state.totalItems,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${state.percentage}%',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}