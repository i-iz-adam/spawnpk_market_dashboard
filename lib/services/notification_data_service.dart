import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



class NotificationDataService {
  static const String _keyNotifiedIds = 'notified_trade_ids';
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyFirstLaunchTime = 'first_launch_time';

  SharedPreferences? _prefs;
  Set<String> _notifiedIds = {};
  bool _isFirstLaunch = true;
  DateTime? _firstLaunchTime;


  Future<void> initialize() async {
    print("=== INITIALIZING NOTIFICATION DATA SERVICE ===");
    
    _prefs = await SharedPreferences.getInstance();


    final idsJson = _prefs?.getString(_keyNotifiedIds);
    if (idsJson != null) {
      try {
        final List<dynamic> idsList = jsonDecode(idsJson);
        _notifiedIds = idsList.cast<String>().toSet();
        print("✓ Loaded ${_notifiedIds.length} notified trade IDs");
      } catch (e) {
        print("⚠ Failed to load notified IDs: $e");
        _notifiedIds = {};
      }
    } else {
      print("  No previous notified IDs found (fresh install)");
    }


    _isFirstLaunch = _prefs?.getBool(_keyFirstLaunch) ?? true;
    
    if (_isFirstLaunch) {

      _firstLaunchTime = DateTime.now();
      await _prefs?.setString(_keyFirstLaunchTime, _firstLaunchTime!.toIso8601String());
      await _prefs?.setBool(_keyFirstLaunch, false);
      print("✓ First launch detected - only trades from past 24h will notify");
      print("  First launch time: $_firstLaunchTime");
    } else {

      final timeStr = _prefs?.getString(_keyFirstLaunchTime);
      if (timeStr != null) {
        try {
          _firstLaunchTime = DateTime.parse(timeStr);
          print("✓ Loaded first launch time: $_firstLaunchTime");
        } catch (e) {
          print("⚠ Failed to parse first launch time: $e");
        }
      }
      print("✓ Returning user - all new trades will notify");
    }
  }





  bool shouldNotify(String tradeId, DateTime tradeTimestamp) {

    if (_notifiedIds.contains(tradeId)) {
      return false;
    }


    if (!_isFirstLaunch || _firstLaunchTime == null) {
      return true;
    }


    final now = DateTime.now();
    final hoursSinceFirstLaunch = now.difference(_firstLaunchTime!).inHours;
    final hoursSinceTrade = now.difference(tradeTimestamp).inHours;


    final shouldNotifyTrade = hoursSinceTrade < 24;
    
    if (!shouldNotifyTrade) {
      print("  Skipping trade $tradeId (${hoursSinceTrade}h old, first launch)");
    }
    
    return shouldNotifyTrade;
  }




  Future<void> markAsNotified(String tradeId) async {
    _notifiedIds.add(tradeId);


    if (_notifiedIds.length > 1000) {
      print("  Cleaning up old notified IDs (keeping most recent 500)");
      final sortedIds = _notifiedIds.toList();

      final toKeep = sortedIds.skip(sortedIds.length - 500).toSet();
      _notifiedIds = toKeep;
    }


    await _saveNotifiedIds();
  }


  bool hasBeenNotified(String tradeId) {
    return _notifiedIds.contains(tradeId);
  }


  int get notifiedCount => _notifiedIds.length;


  bool get isFirstLaunch => _isFirstLaunch;


  DateTime? get firstLaunchTime => _firstLaunchTime;


  Future<void> _saveNotifiedIds() async {
    try {
      final idsJson = jsonEncode(_notifiedIds.toList());
      await _prefs?.setString(_keyNotifiedIds, idsJson);
    } catch (e) {
      print("⚠ Failed to save notified IDs: $e");
    }
  }


  Future<void> clearAll() async {
    print("Clearing all notification data...");
    _notifiedIds.clear();
    await _prefs?.remove(_keyNotifiedIds);
    await _prefs?.remove(_keyFirstLaunch);
    await _prefs?.remove(_keyFirstLaunchTime);
    print("✓ Notification data cleared");
  }


  Future<void> resetFirstLaunch() async {
    print("Resetting first launch state...");
    await _prefs?.setBool(_keyFirstLaunch, true);
    await _prefs?.remove(_keyFirstLaunchTime);
    _isFirstLaunch = true;
    _firstLaunchTime = null;
    print("✓ First launch state reset");
  }
}