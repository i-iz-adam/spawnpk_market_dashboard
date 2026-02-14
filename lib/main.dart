import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/home_page.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await NotificationService.initialize();
  
  runApp(
    const ProviderScope(
      child: SpawnpkMarketDashboardApp(),
    ),
  );
}

class SpawnpkMarketDashboardApp extends ConsumerStatefulWidget {
  const SpawnpkMarketDashboardApp({super.key});

  @override
  ConsumerState<SpawnpkMarketDashboardApp> createState() =>
      _SpawnpkMarketDashboardAppState();
}

class _SpawnpkMarketDashboardAppState
    extends ConsumerState<SpawnpkMarketDashboardApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotificationService();
    });
  }

  Future<void> _initializeNotificationService() async {
    final notificationService = ref.read(notificationServiceProvider);
    

    await notificationService.initializeDataService();
    

    notificationService.startPolling();
    
    print("✓ Notification service fully initialized and polling started");
  }

  @override
  void dispose() {
    ref.read(notificationServiceProvider).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpawnPK Market Dashboard',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomePage(),
    );
  }
}