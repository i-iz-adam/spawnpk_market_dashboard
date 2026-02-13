import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keys for shared_preferences.
abstract class StorageKeys {
  static const String trackedUsers = 'tracked_users';
  static const String trackingPurchases = 'tracking_purchases_';
  static const String trackingSales = 'tracking_sales_';
  static const String pollIntervalSeconds = 'poll_interval_seconds';
}

/// Service for persisting data with shared_preferences.
class StorageService {
  StorageService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _instance async => _prefs ??= await SharedPreferences.getInstance();

  /// Load tracked usernames.
  Future<List<String>> getTrackedUsers() async {
    final p = await _instance;
    final json = p.getString(StorageKeys.trackedUsers);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Save tracked usernames.
  Future<void> setTrackedUsers(List<String> usernames) async {
    final p = await _instance;
    await p.setString(StorageKeys.trackedUsers, jsonEncode(usernames));
  }

  /// Add tracked user.
  Future<void> addTrackedUser(String username) async {
    final users = await getTrackedUsers();
    final normalized = username.trim();
    if (normalized.isEmpty || users.contains(normalized)) return;
    users.add(normalized);
    await setTrackedUsers(users);
  }

  /// Remove tracked user.
  Future<void> removeTrackedUser(String username) async {
    final users = await getTrackedUsers();
    users.remove(username);
    await setTrackedUsers(users);
  }

  /// Get tracking options for a user: purchases enabled.
  Future<bool> getTrackingPurchases(String username) async {
    final p = await _instance;
    return p.getBool('${StorageKeys.trackingPurchases}$username') ?? true;
  }

  /// Set tracking options: purchases.
  Future<void> setTrackingPurchases(String username, bool value) async {
    final p = await _instance;
    await p.setBool('${StorageKeys.trackingPurchases}$username', value);
  }

  /// Get tracking options: sales enabled.
  Future<bool> getTrackingSales(String username) async {
    final p = await _instance;
    return p.getBool('${StorageKeys.trackingSales}$username') ?? true;
  }

  /// Set tracking options: sales.
  Future<void> setTrackingSales(String username, bool value) async {
    final p = await _instance;
    await p.setBool('${StorageKeys.trackingSales}$username', value);
  }

  /// Poll interval in seconds.
  Future<int> getPollIntervalSeconds() async {
    final p = await _instance;
    return p.getInt(StorageKeys.pollIntervalSeconds) ?? 60;
  }

  /// Set poll interval in seconds.
  Future<void> setPollIntervalSeconds(int seconds) async {
    final p = await _instance;
    await p.setInt(StorageKeys.pollIntervalSeconds, seconds);
  }
}
