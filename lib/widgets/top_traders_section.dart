
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/top_trader.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/processing_provider.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/loading_error_widget.dart';

class TopTradersSection extends ConsumerWidget {
  const TopTradersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processingState = ref.watch(processingStateProvider);
    final topTradersAsync = ref.watch(topTradersProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '🏆 Top Traders by Volume',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (processingState.isProcessing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Analyzing ${processingState.processedItems}/${processingState.totalItems}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        

        Text(
          processingState.isProcessing
              ? 'Scanning trades to identify top traders...'
              : 'Highest volume traders in the last 24h',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        

        if (processingState.isProcessing && processingState.totalItems > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: processingState.processedItems / processingState.totalItems,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${processingState.processedItems} of ${processingState.totalItems} items scanned',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${processingState.percentage}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        

        if (processingState.topTraders.isNotEmpty)
          AppCard(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      _buildHeaderCell(context, 'Rank', flex: 1),
                      _buildHeaderCell(context, 'Trader', flex: 3),
                      _buildHeaderCell(context, 'Volume (Gold)', flex: 2, align: TextAlign.right),
                      _buildHeaderCell(context, 'Trades', flex: 1, align: TextAlign.right),
                      _buildHeaderCell(context, 'Avg Trade', flex: 2, align: TextAlign.right),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: processingState.topTraders.length.clamp(0, 10),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final trader = processingState.topTraders[i];
                    return _TraderRow(trader: trader);
                  },
                ),
                

                if (processingState.isProcessing && processingState.topTraders.length < 10)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Analyzing more traders...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
        else
          LoadingErrorWidget<List<TopTrader>>(
            asyncValue: topTradersAsync,
            loadingMessage: 'Calculating top traders...',
            dataBuilder: (traders) {
              if (traders.isEmpty) {
                return AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No trader data available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                );
              }
              
              return AppCard(
                child: Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          _buildHeaderCell(context, 'Rank', flex: 1),
                          _buildHeaderCell(context, 'Trader', flex: 3),
                          _buildHeaderCell(context, 'Volume (Gold)', flex: 2, align: TextAlign.right),
                          _buildHeaderCell(context, 'Trades', flex: 1, align: TextAlign.right),
                          _buildHeaderCell(context, 'Avg Trade', flex: 2, align: TextAlign.right),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: traders.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final trader = traders[i];
                        return _TraderRow(trader: trader);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildHeaderCell(
    BuildContext context,
    String label, {
    int flex = 1,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
        textAlign: align,
      ),
    );
  }
}

class _TraderRow extends ConsumerWidget {
  const _TraderRow({required this.trader});
  
  final TopTrader trader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTop3 = trader.rank <= 3;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(pendingSelectedUserProvider.notifier).state = trader.username;
          ref.read(navigationIndexProvider.notifier).state = 2; // Switch to User Lookup tab
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [

              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    if (isTop3)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _getRankColor(trader.rank).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getRankEmoji(trader.rank),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                    else
                      Text(
                        '#${trader.rank}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
              

              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        trader.username.isNotEmpty ? trader.username[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        trader.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              

              Expanded(
                flex: 2,
                child: Text(
                  formatPrice(trader.totalVolume),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              

              Expanded(
                flex: 1,
                child: Text(
                  trader.tradeCount.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
              

              Expanded(
                flex: 2,
                child: Text(
                  formatPrice(trader.avgTradeValue),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.transparent;
    }
  }
  
  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}