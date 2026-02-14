import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


abstract class StorageKeys {
  static const String trackedUsers = 'tracked_users';
  static const String trackingPurchases = 'tracking_purchases_';
  static const String trackingSales = 'tracking_sales_';
  static const String pollIntervalSeconds = 'poll_interval_seconds';
}


class StorageService {
  StorageService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _instance async => _prefs ??= await SharedPreferences.getInstance();


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


  Future<void> setTrackedUsers(List<String> usernames) async {
    final p = await _instance;
    await p.setString(StorageKeys.trackedUsers, jsonEncode(usernames));
  }


  Future<void> addTrackedUser(String username) async {
    final users = await getTrackedUsers();
    final normalized = username.trim();
    if (normalized.isEmpty || users.contains(normalized)) return;
    users.add(normalized);
    await setTrackedUsers(users);
  }


  Future<void> removeTrackedUser(String username) async {
    final users = await getTrackedUsers();
    users.remove(username);
    await setTrackedUsers(users);
  }


  Future<bool> getTrackingPurchases(String username) async {
    final p = await _instance;
    return p.getBool('${StorageKeys.trackingPurchases}$username') ?? true;
  }


  Future<void> setTrackingPurchases(String username, bool value) async {
    final p = await _instance;
    await p.setBool('${StorageKeys.trackingPurchases}$username', value);
  }


  Future<bool> getTrackingSales(String username) async {
    final p = await _instance;
    return p.getBool('${StorageKeys.trackingSales}$username') ?? true;
  }


  Future<void> setTrackingSales(String username, bool value) async {
    final p = await _instance;
    await p.setBool('${StorageKeys.trackingSales}$username', value);
  }


  Future<int> getPollIntervalSeconds() async {
    final p = await _instance;
    return p.getInt(StorageKeys.pollIntervalSeconds) ?? 60;
  }


  Future<void> setPollIntervalSeconds(int seconds) async {
    final p = await _instance;
    await p.setInt(StorageKeys.pollIntervalSeconds, seconds);
  }
}
