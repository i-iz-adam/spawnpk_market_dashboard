import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/user_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/activity_chart.dart';
import '../widgets/app_card.dart';
import '../widgets/app_summary_card.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/loading_error_widget.dart';
import '../widgets/section_header.dart';

const int _tradesPerPage = 20;

void _showTradeDetailModal(BuildContext context, Trade t, bool isPurchase) {
  final theme = Theme.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isPurchase ? AppColors.success : AppColors.warning)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        isPurchase ? Icons.shopping_cart : Icons.sell,
                        color: isPurchase ? AppColors.success : AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        t.itemName,
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _DetailRow(label: 'Price', value: formatPrice(t.effectivePrice)),
                _DetailRow(label: 'Quantity', value: formatQuantity(t.quantity)),
                _DetailRow(
                    label: 'Total',
                    value: formatPrice(t.effectivePrice * t.quantity)),
                const Divider(height: AppSpacing.xl),
                _DetailRow(
                    label: 'Buyer', value: t.buyer.isNotEmpty ? t.buyer : '—'),
                _DetailRow(
                    label: 'Seller',
                    value: t.seller.isNotEmpty ? t.seller : '—'),
                _DetailRow(
                    label: 'Date & time',
                    value: formatTimestamp(t.timestamp)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Trade #${t.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


class UserLookupPage extends ConsumerStatefulWidget {
  const UserLookupPage({super.key});

  @override
  ConsumerState<UserLookupPage> createState() => _UserLookupPageState();
}

class _UserLookupPageState extends ConsumerState<UserLookupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(selectedUserProvider);
    ref.listen(selectedUserProvider, (prev, next) {
      if (prev != next) {
        ref.read(userTradesSearchQueryProvider.notifier).state = '';
        ref.read(userPurchasesPageProvider.notifier).state = 1;
        ref.read(userSalesPageProvider.notifier).state = 1;
      }
    });

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'User Lookup',
            subtitle: 'View purchases and sales for a username',
          ),
          const SizedBox(height: AppSpacing.xl),
          DebouncedSearchField(
            controller: _searchController,
            hintText: 'Search username...',
            suggestions: const [],
            onSuggestionSelected: (s) {
              ref.read(selectedUserProvider.notifier).state = s;
            },
            onChanged: (query) {
              final trimmed = query.trim();
              if (trimmed.isEmpty) {
                ref.read(selectedUserProvider.notifier).state = null;
              } else {
                ref.read(selectedUserProvider.notifier).state = trimmed;
              }
            },
          ),
          if (selectedUser != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: _UserTradesContent(
                username: selectedUser,
                tabController: _tabController,
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 56,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Enter a username to view trades',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserTradesContent extends ConsumerWidget {
  const _UserTradesContent({
    required this.username,
    required this.tabController,
  });

  final String username;
  final TabController tabController;

  String _toUnderscore(String s) => s.replaceAll(' ', '_');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTradesAsync = ref.watch(userTradesProvider(username));
    final purchasesAsync = ref.watch(userPurchasesProvider(username));
    final salesAsync = ref.watch(userSalesProvider(_toUnderscore(username)));

    return LoadingErrorWidget<TradesResponse>(
      asyncValue: allTradesAsync,
      loadingMessage: 'Loading user trades...',
      dataBuilder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Theme.of(context).dividerColor,
              tabs: const [
                Tab(text: 'Purchases'),
                Tab(text: 'Sales'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _UserTabContent(
                    tradesAsync: purchasesAsync,
                    username: username,
                    isPurchase: true,
                  ),
                  _UserTabContent(
                    tradesAsync: salesAsync,
                    username: _toUnderscore(username),
                    isPurchase: false,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserTabContent extends ConsumerWidget {
  const _UserTabContent({
    required this.tradesAsync,
    required this.username,
    required this.isPurchase,
  });

  final AsyncValue<TradesResponse> tradesAsync;
  final String username;
  final bool isPurchase;

  static bool _matchesQuery(Trade t, String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return t.itemName.toLowerCase().contains(lower) ||
        t.buyer.toLowerCase().contains(lower) ||
        t.seller.toLowerCase().contains(lower);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(userTradesSearchQueryProvider);
    final pageProvider =
        isPurchase ? userPurchasesPageProvider : userSalesPageProvider;
    final page = ref.watch(pageProvider);

    return LoadingErrorWidget<TradesResponse>(
      asyncValue: tradesAsync,
      loadingMessage: 'Loading...',
      dataBuilder: (response) {
        final allTrades = response.trades;
        final filtered =
            allTrades.where((t) => _matchesQuery(t, searchQuery)).toList();
        final totalFiltered = filtered.length;
        final totalPages =
            (totalFiltered / _tradesPerPage).ceil().clamp(1, 999999);
        final pageIndex = page.clamp(1, totalPages);
        if (pageIndex != page) {
          Future.microtask(
              () => ref.read(pageProvider.notifier).state = pageIndex);
        }
        final start = (pageIndex - 1) * _tradesPerPage;
        final end = start + _tradesPerPage > filtered.length
            ? filtered.length
            : start + _tradesPerPage;
        final pageTrades = start >= filtered.length
            ? <Trade>[]
            : filtered.sublist(start, end);

        double totalValue = 0;
        double totalVolume = 0;
        for (final t in filtered) {
          totalValue += t.effectivePrice * t.quantity;
          totalVolume += t.quantity.toDouble();
        }
        final avgPrice = filtered.isEmpty
            ? 0.0
            : (totalVolume > 0 ? totalValue / totalVolume : 0.0);

        return Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppSummaryCard(
                        title: 'Total Value',
                        value: formatPrice(totalValue),
                        icon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppSummaryCard(
                        title: 'Volume',
                        value: formatQuantity(totalVolume.toInt()),
                        icon: Icons.inventory_2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppSummaryCard(
                        title: 'Avg Price',
                        value: formatPrice(avgPrice),
                        icon: Icons.trending_up,
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
                        'Activity Over Time',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ActivityChart(trades: allTrades),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPurchase ? 'Purchases' : 'Sales',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(
                            width: 280,
                            child: TextField(
                              key: ValueKey('trades_filter_$username'),
                              onChanged: (v) {
                                ref
                                    .read(userTradesSearchQueryProvider.notifier)
                                    .state = v.trim();
                                ref.read(pageProvider.notifier).state = 1;
                              },
                              decoration: InputDecoration(
                                hintText: 'Filter by item, buyer, seller…',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 10,
                                ),
                                prefixIcon: const Icon(Icons.search, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No ${isPurchase ? 'purchases' : 'sales'} found'
                                  : 'No matches for "$searchQuery"',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pageTrades.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final t = pageTrades[i];
                                return _TradeRow(
                                  trade: t,
                                  isPurchase: isPurchase,
                                  onTap: () =>
                                      _showTradeDetailModal(
                                          context, t, isPurchase),
                                );
                              },
                            ),
                            if (totalPages > 1) ...[
                              const Divider(height: AppSpacing.xl),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    onPressed: pageIndex > 1
                                        ? () => ref
                                            .read(pageProvider.notifier)
                                            .state = pageIndex - 1
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                    label: const Text('Previous'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 44),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Text(
                                    'Page $pageIndex of $totalPages',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  FilledButton.icon(
                                    onPressed: pageIndex < totalPages
                                        ? () => ref
                                            .read(pageProvider.notifier)
                                            .state = pageIndex + 1
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                    label: const Text('Next'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 44),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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

class _TradeRow extends StatelessWidget {
  const _TradeRow({
    required this.trade,
    required this.isPurchase,
    required this.onTap,
  });

  final Trade trade;
  final bool isPurchase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = trade;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPurchase ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isPurchase ? Icons.shopping_cart : Icons.sell,
                  color: isPurchase ? AppColors.success : AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.lg - 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatPrice(t.effectivePrice)} × ${formatQuantity(t.quantity)} • ${formatTimestamp(t.timestamp)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
