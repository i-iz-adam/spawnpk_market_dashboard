import 'package:intl/intl.dart';


String formatPrice(num price) {
  final n = price.toDouble();
  final abs = n.abs();
  final sign = n < 0 ? '-' : '';
  if (abs >= 1e12) {
    final v = abs / 1e12;
    return '$sign${_compactDecimal(v)}t';
  }
  if (abs >= 1e9) {
    final v = abs / 1e9;
    return '$sign${_compactDecimal(v)}b';
  }
  if (abs >= 1e6) {
    final v = abs / 1e6;
    return '$sign${_compactDecimal(v)}m';
  }
  if (abs >= 1e3) {
    final v = abs / 1e3;
    return '$sign${_compactDecimal(v)}k';
  }
  return '$sign${NumberFormat('#,###').format(n)}';
}

String _compactDecimal(double v) {
  if (v >= 100 || v == v.truncateToDouble()) {
    return v.truncate().toString();
  }
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}


String formatQuantity(int qty) {
  return NumberFormat('#,###').format(qty);
}


String formatTimestamp(DateTime dt) {
  return DateFormat('MMM d, y HH:mm').format(dt);
}


String formatDate(DateTime dt) {
  return DateFormat('MMM d').format(dt);
}
