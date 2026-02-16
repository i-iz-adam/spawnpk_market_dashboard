import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spawnpk_market_dashboard/providers/item_providers.dart';

import '../../models/trade.dart';
import '../../providers/app_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_summary_card.dart';
import '../../widgets/loading_error_widget.dart';
import '../../pages/item_lookup_page.dart';
import '../../pages/user_lookup_page.dart';
import '../../pages/user_tracking_page.dart';

class QuickActionsColumn extends ConsumerWidget {
  const QuickActionsColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedUsersAsync = ref.watch(trackedUsersWithActivityProvider);
    final selectedUser = ref.watch(selectedUserProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Item Search',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    ref.read(selectedItemProvider.notifier).state = query;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ItemLookupPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        

        if (selectedUser != null)
          _UserSummaryCard(username: selectedUser)
        else
          AppCard(
            child: Column(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 40,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No User Selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Search for a user to see their stats',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserLookupPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Find User'),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tracked Users',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserTrackingPage(),
                        ),
                      );
                    },
                    child: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              trackedUsersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Text(
                          'No tracked users',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final user = users[i];
                      final username = user['username'] as String;
                      final lastTrade = user['lastTrade'] as Trade?;
                      
                      return _TrackedUserTile(
                        username: username,
                        lastTrade: lastTrade,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'Failed to load tracked users',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserSummaryCard extends ConsumerWidget {
  const _UserSummaryCard({required this.username});
  
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTradesAsync = ref.watch(userTradesProvider(username));
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Active Trader',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          userTradesAsync.when(
            data: (response) {
              final trades = response.trades;
              final totalVolume = trades.fold<double>(
                0, (sum, t) => sum + (t.effectivePrice * t.quantity),
              );
              final recentTrades = trades.where((t) => 
                DateTime.now().difference(t.timestamp).inHours < 24
              ).length;
              
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          label: 'Total Volume',
                          value: formatPrice(totalVolume),
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatChip(
                          label: '24h Trades',
                          value: recentTrades.toString(),
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const Text('Could not load stats'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () {
              ref.read(selectedUserProvider.notifier).state = username;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserLookupPage(),
                ),
              );
            },
            child: const Text('View Full Analysis'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
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

class _TrackedUserTile extends ConsumerWidget {
  const _TrackedUserTile({
    required this.username,
    required this.lastTrade,
  });
  
  final String username;
  final Trade? lastTrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(selectedUserProvider.notifier).state = username;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserLookupPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (lastTrade != null)
                      Text(
                        'Last trade: ${formatTimestamp(lastTrade!.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              if (lastTrade != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}