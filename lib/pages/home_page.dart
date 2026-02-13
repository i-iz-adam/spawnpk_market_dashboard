import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item_lookup_page.dart';
import 'user_lookup_page.dart';
import 'user_tracking_page.dart';

/// Root page with navigation drawer.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    ItemLookupPage(),
    UserLookupPage(),
    UserTrackingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpawnPK Market Dashboard'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            backgroundColor: const Color(0xFF151515),
            selectedIconTheme: IconThemeData(color: Colors.teal.shade400),
            unselectedIconTheme: IconThemeData(color: Colors.grey[500]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2),
                label: Text('Item Lookup'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_search),
                label: Text('User Lookup'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.notifications_active),
                label: Text('User Tracking'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
