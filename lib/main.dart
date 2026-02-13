import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/home_page.dart';
import 'services/notification_service.dart';

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
      ref.read(notificationServiceProvider).startPolling();
    });
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
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.teal.shade400,
          secondary: Colors.amber.shade400,
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
