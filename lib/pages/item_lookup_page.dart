import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../providers/item_providers.dart';
import '../utils/formatters.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/loading_error_widget.dart';
import '../widgets/price_history_chart.dart';

/// Page for looking up items and viewing recent trades.
class ItemLookupPage extends ConsumerWidget {
  const ItemLookupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemNamesAsync = ref.watch(itemNamesProvider);
    final selectedItem = ref.watch(selectedItemProvider);
    final page = ref.watch(itemTradesPageProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Item Lookup',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          itemNamesAsync.when(
            data: (names) => DebouncedSearchField(
              hintText: 'Search items...',
              suggestions: names,
              onSuggestionSelected: (s) {
                ref.read(selectedItemProvider.notifier).state = s;
                ref.read(itemTradesPageProvider.notifier).state = 1;
              },
              onChanged: (query) {
                if (query.isEmpty) {
                  ref.read(selectedItemProvider.notifier).state = null;
                }
              },
            ),
            loading: () => const TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Loading items...',
                border: OutlineInputBorder(),
              ),
            ),
            error: (e, _) => Text(
              'Failed to load items: $e',
              style: TextStyle(color: Colors.red[300]),
            ),
          ),
          if (selectedItem != null) ...[
            const SizedBox(height: 24),
            Expanded(
              child: _ItemTradesContent(
                itemName: selectedItem,
                page: page,
                onPageChanged: (p) {
                  ref.read(itemTradesPageProvider.notifier).state = p;
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'Select an item to view trades and price history',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemTradesContent extends ConsumerWidget {
  const _ItemTradesContent({
    required this.itemName,
    required this.page,
    required this.onPageChanged,
  });

  final String itemName;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(itemTradesProvider((itemName: itemName, page: page)));

    return LoadingErrorWidget<TradesResponse>(
      asyncValue: tradesAsync,
      loadingMessage: 'Loading trades...',
      dataBuilder: (response) {
        final trades = response.trades;
        final pagination = response.pagination;

        // Compute summary.
        double avgPrice = 0;
        double minPrice = 0;
        double maxPrice = 0;
        int volume = 0;
        if (trades.isNotEmpty) {
          final prices = trades.map((t) => t.price).toList();
          avgPrice = prices.reduce((a, b) => a + b) / prices.length;
          minPrice = prices.reduce((a, b) => a < b ? a : b);
          maxPrice = prices.reduce((a, b) => a > b ? a : b);
          volume = trades.fold(0, (s, t) => s + t.quantity);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Avg Price',
                      value: formatPrice(avgPrice),
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Min / Max',
                      value: '${formatPrice(minPrice)} / ${formatPrice(maxPrice)}',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Volume',
                      value: formatQuantity(volume),
                      icon: Icons.inventory_2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Price history chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      PriceHistoryChart(trades: trades),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Trades list
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Trades',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (pagination.totalPages > 1)
                            Row(
                              children: [
                                IconButton(
                                  onPressed: pagination.hasPrevPage
                                      ? () => onPageChanged(page - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text(
                                  '${pagination.page} / ${pagination.totalPages}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                IconButton(
                                  onPressed: pagination.hasNextPage
                                      ? () => onPageChanged(page + 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (trades.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No trades found for this item',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: trades.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final t = trades[i];
                            return ListTile(
                              title: Text(
                                '${formatPrice(t.price)} x ${formatQuantity(t.quantity)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${t.buyer} ↔ ${t.seller} • ${formatTimestamp(t.timestamp)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
