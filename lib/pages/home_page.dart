
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../providers/user_providers.dart';
import '../providers/item_providers.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_page.dart';
import 'item_lookup_page.dart';
import 'user_lookup_page.dart';
import 'user_tracking_page.dart';
import 'update_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _selectedIndex;

  static const List<Widget> _pages = [
    DashboardPage(),
    ItemLookupPage(),
    UserLookupPage(),
    UserTrackingPage(),
    UpdatePage(),
  ];

  static const List<String> _destinationLabels = [
    'Dashboard',
    'Items',
    'Users',
    'Tracking',
    'Updates',
  ];

  static const List<IconData> _destinationIcons = [
    Icons.dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.person_search_outlined,
    Icons.notifications_outlined,
    Icons.system_update_outlined,
  ];

  static const List<IconData> _selectedIcons = [
    Icons.dashboard,
    Icons.inventory_2,
    Icons.person_search,
    Icons.notifications_active,
    Icons.system_update,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = ref.read(navigationIndexProvider);
  }

  @override
  Widget build(BuildContext context) {

    ref.listen<int>(navigationIndexProvider, (_, newIndex) {
      if (mounted) {
        setState(() {
          _selectedIndex = newIndex;
        });
      }
    });


    ref.listen<String?>(pendingSelectedUserProvider, (_, username) {
      if (username != null && _selectedIndex != 2) {

        ref.read(navigationIndexProvider.notifier).state = 2;
      }
    });


    ref.listen<String?>(pendingSelectedItemProvider, (_, itemName) {
      if (itemName != null && _selectedIndex != 1) {

        ref.read(navigationIndexProvider.notifier).state = 1;
      }
    });

    return Scaffold(
      body: Row(
        children: [
          _buildNavRail(context),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'SpawnPK Market Dashboard',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const Spacer(),
                          if (_selectedIndex != 0)
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                ref.read(navigationIndexProvider.notifier).state = 0;
                              },
                              tooltip: 'Back to Dashboard',
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey<int>(_selectedIndex),
                          child: _pages[_selectedIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRail(BuildContext context) {
    return Container(
      width: 88,
      margin: const EdgeInsets.only(
        left: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          ref.read(navigationIndexProvider.notifier).state = i;
        },
        backgroundColor: Colors.transparent,
        extended: false,
        leading: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.md,
          ),
          child: Text(
            'Market',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        destinations: List.generate(_destinationLabels.length, (i) {
          return NavigationRailDestination(
            icon: Icon(_destinationIcons[i]),
            selectedIcon: Icon(_selectedIcons[i]),
            label: Text(_destinationLabels[i]),
          );
        }),
      ),
    );
  }
}