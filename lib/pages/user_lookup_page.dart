import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/user_providers.dart';
import '../utils/formatters.dart';
import '../widgets/activity_chart.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/loading_error_widget.dart';

/// Page for looking up users and viewing their trades.
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'User Lookup',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          DebouncedSearchField(
            controller: _searchController,
            hintText: 'Search username...',
            suggestions: const [], // Username search - no item suggestions
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
            const SizedBox(height: 24),
            Expanded(
              child: _UserTradesContent(
                username: selectedUser,
                tabController: _tabController,
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'Enter a username to view trades',
                  style: TextStyle(color: Colors.grey[500]),
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
              tabs: const [
                Tab(text: 'Purchases'),
                Tab(text: 'Sales'),
              ],
            ),
            const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LoadingErrorWidget<TradesResponse>(
      asyncValue: tradesAsync,
      loadingMessage: 'Loading...',
      dataBuilder: (response) {
        final trades = response.trades;

        // Totals
        double totalValue = 0;
        double totalVolume = 0;
        for (final t in trades) {
          totalValue += t.price * t.quantity;
          totalVolume += t.quantity.toDouble();
        }
        final avgPrice = trades.isEmpty ? 0.0 : (totalVolume > 0 ? totalValue / totalVolume : 0.0);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Value',
                      value: formatPrice(totalValue),
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Volume',
                      value: formatQuantity(totalVolume.toInt()),
                      icon: Icons.inventory_2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Avg Price',
                      value: formatPrice(avgPrice),
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Activity graph
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Over Time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ActivityChart(trades: trades),
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
                      Text(
                        isPurchase ? 'Purchases' : 'Sales',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (trades.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No ${isPurchase ? 'purchases' : 'sales'} found',
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
                              leading: Icon(
                                isPurchase ? Icons.shopping_cart : Icons.sell,
                                color: isPurchase ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                              title: Text(
                                t.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${formatPrice(t.price)} x ${formatQuantity(t.quantity)} • ${formatTimestamp(t.timestamp)}',
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
