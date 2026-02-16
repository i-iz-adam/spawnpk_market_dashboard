
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hot_item.dart';
import '../providers/dashboard_providers.dart';
import '../providers/processing_provider.dart';
import '../providers/item_providers.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'loading_error_widget.dart';

class HotItemsColumn extends ConsumerWidget {
  const HotItemsColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processingState = ref.watch(processingStateProvider);
    final hotItemsAsync = ref.watch(hotItemsProvider);
    
    print('🔄 HotItemsColumn building - isProcessing: ${processingState.isProcessing}, processed: ${processingState.processedItems}/${processingState.totalItems}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.whatshot,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '🔥 Hot Items Right Now',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (processingState.isProcessing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${processingState.processedItems}/${processingState.totalItems}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
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
              ? 'Scanning: ${processingState.currentItem}'
              : 'Items with unusual price or volume activity',
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${processingState.processedItems} of ${processingState.totalItems} items',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '${processingState.percentage}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        

        if (processingState.hotItems.isNotEmpty)
          ...processingState.hotItems.take(5).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _HotItemCard(item: item),
            );
          }).toList()
        

        else if (processingState.isProcessing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Scanning for hot items...',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          )
        

        else
          LoadingErrorWidget<List<HotItem>>(
            asyncValue: hotItemsAsync,
            loadingMessage: 'Analyzing market activity...',
            dataBuilder: (hotItems) {
              if (hotItems.isEmpty) {
                return _EmptyState();
              }
              return Column(
                children: hotItems.take(5).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _HotItemCard(item: item),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No significant activity detected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check back soon for market movers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HotItemCard extends ConsumerWidget {
  const _HotItemCard({required this.item});
  
  final HotItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPriceUp = item.priceChangePercent > 0;
    final priceColor = isPriceUp ? Colors.green : Colors.red;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(selectedItemProvider.notifier).state = item.itemName;
          ref.read(pendingSelectedItemProvider.notifier).state = item.itemName;
          ref.read(navigationIndexProvider.notifier).state = 1; // Switch to Item Lookup tab
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AppCard(
          elevateOnHover: true,
          child: Column(
            children: [

              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      formatTimestamp(item.lastTradeTime),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              

              Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              formatPrice(item.currentPrice),
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: priceColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: priceColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item.priceChangePercent.abs().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: priceColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  

                  if (item.volumeSurge > 1.5)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.blue,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.volumeSurge.toStringAsFixed(1)}x volume',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              

              Row(
                children: [
                  _buildStat(
                    context,
                    label: 'Trades (1h)',
                    value: item.tradeCount.toString(),
                    icon: Icons.swap_horiz,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildStat(
                    context,
                    label: 'Avg Volume',
                    value: formatQuantity(item.avgVolume),
                    icon: Icons.inventory,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStat(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}