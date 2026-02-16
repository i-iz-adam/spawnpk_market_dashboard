
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final unreadNotificationsProvider = StateNotifierProvider<UnreadNotificationsNotifier, int>((ref) {
  return UnreadNotificationsNotifier();
});

class UnreadNotificationsNotifier extends StateNotifier<int> {
  UnreadNotificationsNotifier() : super(0);

  void increment() => state++;
  void reset() => state = 0;
  void setCount(int count) => state = count;
}


final lastViewedNotificationProvider = StateProvider<DateTime?>((ref) => null);