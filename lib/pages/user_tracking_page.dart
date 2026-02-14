import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';


class UserTrackingPage extends ConsumerStatefulWidget {
  const UserTrackingPage({super.key});

  @override
  ConsumerState<UserTrackingPage> createState() => _UserTrackingPageState();
}

class _UserTrackingPageState extends ConsumerState<UserTrackingPage> {
  final _usernameController = TextEditingController();
  final _pollIntervalController = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    _loadPollInterval();
  }

  Future<void> _loadPollInterval() async {
    final storage = ref.read(storageServiceProvider);
    final interval = await storage.getPollIntervalSeconds();
    if (mounted) {
      ref.read(pollIntervalProvider.notifier).state = interval;
      _pollIntervalController.text = interval.toString();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pollIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackedUsersAsync = ref.watch(trackedUsersProvider);
    final pollInterval = ref.watch(pollIntervalProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'User Tracking',
            subtitle: 'Get notified when tracked users buy or sell',
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Tracked User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Username',
                        ),
                        onSubmitted: (_) => _addUser(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _addUser,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Notification Poll Interval',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Text('Poll every '),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _pollIntervalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n >= 10 && n <= 3600) {
                            ref.read(pollIntervalProvider.notifier).state = n;
                            ref
                                .read(storageServiceProvider)
                                .setPollIntervalSeconds(n);
                          } else {
                            _pollIntervalController.text =
                                pollInterval.toString();
                          }
                        },
                      ),
                    ),
                    const Text(' seconds'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Notifications will check for new trades every $pollInterval seconds',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Tracked Users',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: trackedUsersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 56,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No tracked users. Add one above.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return Scrollbar(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final username = users[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TrackedUserTile(
                          username: username,
                          onRemove: () => _removeUser(username),
                          onTogglePurchases: (v) =>
                              _setTrackingPurchases(username, v),
                          onToggleSales: (v) =>
                              _setTrackingSales(username, v),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addUser() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;
    final storage = ref.read(storageServiceProvider);
    await storage.addTrackedUser(username);
    _usernameController.clear();
    ref.invalidate(trackedUsersProvider);
  }

  Future<void> _removeUser(String username) async {
    final storage = ref.read(storageServiceProvider);
    await storage.removeTrackedUser(username);
    ref.invalidate(trackedUsersProvider);
  }

  Future<void> _setTrackingPurchases(String username, bool value) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setTrackingPurchases(username, value);
    ref.invalidate(trackedUsersProvider);
  }

  Future<void> _setTrackingSales(String username, bool value) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setTrackingSales(username, value);
    ref.invalidate(trackedUsersProvider);
  }
}

class _TrackedUserTile extends ConsumerStatefulWidget {
  const _TrackedUserTile({
    required this.username,
    required this.onRemove,
    required this.onTogglePurchases,
    required this.onToggleSales,
  });

  final String username;
  final VoidCallback onRemove;
  final ValueChanged<bool> onTogglePurchases;
  final ValueChanged<bool> onToggleSales;

  @override
  ConsumerState<_TrackedUserTile> createState() => _TrackedUserTileState();
}

class _TrackedUserTileState extends ConsumerState<_TrackedUserTile> {
  bool _trackPurchases = true;
  bool _trackSales = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final storage = ref.read(storageServiceProvider);
    final purchases = await storage.getTrackingPurchases(widget.username);
    final sales = await storage.getTrackingSales(widget.username);
    if (mounted) {
      setState(() {
        _trackPurchases = purchases;
        _trackSales = sales;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilterChip(
                            label: const Text('Purchases'),
                            selected: _trackPurchases,
                            onSelected: (v) {
                              setState(() => _trackPurchases = v);
                              widget.onTogglePurchases(v);
                            },
                            showCheckmark: true,
                          ),
                          FilterChip(
                            label: const Text('Sales'),
                            selected: _trackSales,
                            onSelected: (v) {
                              setState(() => _trackSales = v);
                              widget.onToggleSales(v);
                            },
                            showCheckmark: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                    size: 22,
                  ),
                  onPressed: widget.onRemove,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                  ),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
