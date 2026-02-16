
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../providers/item_providers.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/app_summary_card.dart';
import '../widgets/loading_error_widget.dart';
import '../widgets/price_history_chart.dart';
import '../widgets/section_header.dart';

class ItemLookupPage extends ConsumerStatefulWidget {
  const ItemLookupPage({super.key});

  @override
  ConsumerState<ItemLookupPage> createState() => _ItemLookupPageState();
}

class _ItemLookupPageState extends ConsumerState<ItemLookupPage> {
  TextEditingController? _autocompleteController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingItem = ref.read(pendingSelectedItemProvider);
      if (pendingItem != null) {
        ref.read(selectedItemProvider.notifier).state = pendingItem;
        ref.read(pendingSelectedItemProvider.notifier).state = null;
        ref.read(itemTradesPageProvider.notifier).state = 1;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemNamesAsync = ref.watch(itemNamesProvider);
    final selectedItem = ref.watch(selectedItemProvider);
    final page = ref.watch(itemTradesPageProvider);

    return Container(
      color: Colors.transparent, // Make container transparent
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Item Lookup',
              subtitle: 'Search items and view trade history',
            ),
            const SizedBox(height: AppSpacing.xl),
            itemNamesAsync.when(
              data: (names) => RawAutocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return names.where(
                    (name) => name.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                  );
                },
                onSelected: (selection) {
                  print('onSelected called with: $selection');
                  _autocompleteController?.text = selection;
                  ref.read(selectedItemProvider.notifier).state = selection;
                  ref.read(itemTradesPageProvider.notifier).state = 1;
                  _focusNode.unfocus();
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  _autocompleteController = textController;
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    onSubmitted: (value) {
                      final q = value.trim();
                      if (q.isEmpty) return;
                      final match = names.where((n) => n.toLowerCase() == q.toLowerCase()).toList();
                      if (match.isNotEmpty) {
                        textController.text = match.first;
                        ref.read(selectedItemProvider.notifier).state = match.first;
                        ref.read(itemTradesPageProvider.notifier).state = 1;
                        focusNode.unfocus();
                      }
                    },
                    onChanged: (query) {
                      if (query.trim().isEmpty) {
                        ref.read(selectedItemProvider.notifier).state = null;
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        width: 400,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Loading items...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              error: (e, _) => Text(
                'Failed to load items: $e',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            if (selectedItem != null) ...[
              const SizedBox(height: AppSpacing.xl),
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
                child: _EmptyState(
                  icon: Icons.search,
                  message: 'Select an item to view trades and price history',
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
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
    final tradesAsync =
        ref.watch(itemTradesProvider((itemDisplayName: itemName, page: page)));

    return LoadingErrorWidget<TradesResponse>(
      asyncValue: tradesAsync,
      loadingMessage: 'Loading trades...',
      dataBuilder: (response) {
        final trades = response.trades;
        final pagination = response.pagination;

        double avgPrice = 0;
        double minPrice = 0;
        double maxPrice = 0;
        int volume = 0;
        if (trades.isNotEmpty) {
          final prices = trades.map((t) => t.effectivePrice).toList();
          avgPrice = prices.reduce((a, b) => a + b) / prices.length;
          minPrice = prices.reduce((a, b) => a < b ? a : b);
          maxPrice = prices.reduce((a, b) => a > b ? a : b);
          volume = trades.fold(0, (s, t) => s + t.quantity);
        }

        return Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppSummaryCard(
                        title: 'Avg Price',
                        value: formatPrice(avgPrice),
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppSummaryCard(
                        title: 'Min / Max',
                        value: '${formatPrice(minPrice)} / ${formatPrice(maxPrice)}',
                        icon: Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppSummaryCard(
                        title: 'Volume',
                        value: formatQuantity(volume),
                        icon: Icons.inventory_2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PriceHistoryChart(trades: trades),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Trades',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (pagination.totalPages > 1)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: pagination.hasPrevPage
                                      ? () => onPageChanged(page - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(40, 40),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  child: Text(
                                    '${pagination.page} / ${pagination.totalPages}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                IconButton(
                                  onPressed: pagination.hasNextPage
                                      ? () => onPageChanged(page + 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(40, 40),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (trades.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Text(
                              'No trades found for this item',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
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
                            return _TradeListTile(
                              title:
                                  '${formatPrice(t.effectivePrice)} x ${formatQuantity(t.quantity)}',
                              subtitle:
                                  '${t.buyer} ↔ ${t.seller} • ${formatTimestamp(t.timestamp)}',
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TradeListTile extends StatefulWidget {
  const _TradeListTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<_TradeListTile> createState() => _TradeListTileState();
}

class _TradeListTileState extends State<_TradeListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        child: ListTile(
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          minVerticalPadding: AppSpacing.md,
        ),
      ),
    );
  }
}