import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Page for managing tracked usernames and notification settings.
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'User Tracking',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          // Add user
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Tracked User',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                          ),
                          onSubmitted: (_) => _addUser(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _addUser,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Poll interval
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Notification Poll Interval',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Poll every '),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _pollIntervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                          onSubmitted: (v) {
                            final n = int.tryParse(v);
                            if (n != null && n >= 10 && n <= 3600) {
                              ref.read(pollIntervalProvider.notifier).state = n;
                              ref.read(storageServiceProvider).setPollIntervalSeconds(n);
                            } else {
                              _pollIntervalController.text = pollInterval.toString();
                            }
                          },
                        ),
                      ),
                      const Text(' seconds'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifications will check for new trades every $pollInterval seconds',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Tracked users list
          Text(
            'Tracked Users',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: trackedUsersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No tracked users. Add one above.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final username = users[i];
                    return _TrackedUserTile(
                      username: username,
                      onRemove: () => _removeUser(username),
                      onTogglePurchases: (v) => _setTrackingPurchases(username, v),
                      onToggleSales: (v) => _setTrackingSales(username, v),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: Colors.red[300]),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          widget.username,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            FilterChip(
              label: const Text('Purchases'),
              selected: _trackPurchases,
              onSelected: (v) {
                setState(() => _trackPurchases = v);
                widget.onTogglePurchases(v);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Sales'),
              selected: _trackSales,
              onSelected: (v) {
                setState(() => _trackSales = v);
                widget.onToggleSales(v);
              },
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: widget.onRemove,
        ),
      ),
    );
  }
}
