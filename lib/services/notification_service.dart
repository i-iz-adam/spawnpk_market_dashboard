import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trade.dart';
import '../providers/app_providers.dart';
import '../utils/formatters.dart';

/// Handles Windows desktop notifications for tracked user trades.
class NotificationService {
  NotificationService(this._api, this._storage);

  final dynamic _api;
  final dynamic _storage;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Timer? _pollTimer;
  final Set<String> _lastKnownTradeIds = {};

  static Future<void> initialize() async {
    // Minimal initialization - plugin uses platform defaults
    const initSettings = InitializationSettings();
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Optional: handle tap
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
      // Ignore polling errors
    }
  }

  Future<void> _maybeNotify(Trade t, String username, {required bool isPurchase}) async {
    final id = '${t.id}_${t.timestamp.millisecondsSinceEpoch}';
    if (_lastKnownTradeIds.contains(id)) return;
    _lastKnownTradeIds.add(id);

    // Keep set bounded
    if (_lastKnownTradeIds.length > 500) {
      final toRemove = _lastKnownTradeIds.take(250).toSet();
      _lastKnownTradeIds.removeAll(toRemove);
    }

    final title = isPurchase ? 'Purchase' : 'Sale';
    final body =
        '$username: ${t.itemName} @ ${formatPrice(t.price)} x ${formatQuantity(t.quantity)} - ${formatTimestamp(t.timestamp)}';

    await _plugin.show(
      t.id.hashCode.abs() % 100000,
      '$title - $username',
      body,
      const NotificationDetails(),
    );
  }
}

/// Provider for notification service.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return NotificationService(api, storage);
});
