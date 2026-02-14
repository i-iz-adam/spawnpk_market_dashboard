import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:path/path.dart' as path;

import '../models/trade.dart';
import '../providers/app_providers.dart';
import '../utils/formatters.dart';
import 'notification_data_service.dart';


class NotificationService {
  NotificationService(this._api, this._storage);

  final dynamic _api;
  final dynamic _storage;

  static WindowsNotification? _winNotify;
  static String? _iconPath;
  
  final NotificationDataService _dataService = NotificationDataService();

  Timer? _pollTimer;

  static Future<void> initialize() async {
    print("=== INITIALIZING NOTIFICATION SERVICE ===");
    
    if (Platform.isWindows) {
      try {
        _winNotify = WindowsNotification(
          applicationId: r'com.spkmarket.SPKMarket',
        );
        

        final possiblePaths = [
          path.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'icon.png'),
          path.join(Directory.current.path, 'assets', 'icon.png'),
          path.join(path.dirname(Platform.resolvedExecutable), 'data', 'flutter_assets', 'assets', 'icon.png'),
        ];
        
        for (final iconPath in possiblePaths) {
          if (File(iconPath).existsSync()) {
            _iconPath = iconPath;
            print("✓ Found icon at: $_iconPath");
            break;
          }
        }
        
        if (_iconPath == null) {
          print("⚠ Warning: Icon file not found. Notifications will show without icon.");
        }
        
        print("✓ Windows notification initialized successfully");
      } catch (e) {
        print("✗ Failed to initialize Windows notification: $e");
      }
    }
  }


  Future<void> initializeDataService() async {
    await _dataService.initialize();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _poll();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _poll() {
    _doPoll().then((_) async {
      final interval = await _storage.getPollIntervalSeconds();
      _pollTimer = Timer(Duration(seconds: interval), _poll);
    });
  }

  Future<void> _doPoll() async {
    try {
      final users = await _storage.getTrackedUsers();
      for (final username in users) {
        final trackPurchases = await _storage.getTrackingPurchases(username);
        final trackSales = await _storage.getTrackingSales(username);

        if (trackPurchases) {
          final response = await _api.fetchPurchasesForUser(username);
          for (final t in response.trades) {
            await _maybeNotify(t, username, isPurchase: true);
          }
        }

        if (trackSales) {
          final sellerUsername = username.replaceAll(' ', '_');
          final response = await _api.fetchSalesForUser(sellerUsername);
          for (final t in response.trades) {
            await _maybeNotify(t, username, isPurchase: false);
          }
        }
      }
    } catch (_) {

    }
  }

  Future<void> _maybeNotify(Trade t, String username, {required bool isPurchase}) async {
    final id = '${t.id}_${t.timestamp.millisecondsSinceEpoch}';
    

    if (!_dataService.shouldNotify(id, t.timestamp)) {

      return;
    }



    await _dataService.markAsNotified(id);

    final title = isPurchase ? 'Purchase' : 'Sale';
    final body =
        '$username: ${t.itemName} @ ${formatPrice(t.effectivePrice)} x ${formatQuantity(t.quantity)} - ${formatTimestamp(t.timestamp)}';
    
    print("Showing notification for $username, $body");
    
    if (Platform.isWindows && _winNotify != null) {
      try {
        final notificationId = '${t.id.hashCode.abs() % 100000}';
        
        final message = NotificationMessage.fromPluginTemplate(
          notificationId,
          '$title - $username',
          body,
          image: _iconPath,
        );
        
        await _winNotify!.showNotificationPluginTemplate(message);
        
      } catch (e) {
        print("Error showing notification: $e");
      }
    }
  }


  Map<String, dynamic> getStats() {
    return {
      'notified_count': _dataService.notifiedCount,
      'is_first_launch': _dataService.isFirstLaunch,
      'first_launch_time': _dataService.firstLaunchTime?.toIso8601String(),
    };
  }


  Future<void> clearHistory() async {
    await _dataService.clearAll();
  }


  Future<void> resetFirstLaunch() async {
    await _dataService.resetFirstLaunch();
  }
}


final notificationServiceProvider = Provider<NotificationService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return NotificationService(api, storage);
});