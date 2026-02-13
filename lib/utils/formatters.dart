import 'package:intl/intl.dart';

/// Format a number as currency (e.g. 1,234,567).
String formatPrice(num price) {
  return NumberFormat('#,###').format(price);
}

/// Format quantity.
String formatQuantity(int qty) {
  return NumberFormat('#,###').format(qty);
}

/// Format timestamp for display.
String formatTimestamp(DateTime dt) {
  return DateFormat('MMM d, y HH:mm').format(dt);
}

/// Format date for short display.
String formatDate(DateTime dt) {
  return DateFormat('MMM d').format(dt);
}
