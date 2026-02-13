/// Model for a single trade from the trades API.
class Trade {
  const Trade({
    required this.id,
    required this.itemName,
    required this.price,
    required this.quantity,
    required this.buyer,
    required this.seller,
    required this.timestamp,
    this.type,
  });

  final int id;
  final String itemName;
  final double price;
  final int quantity;
  final String buyer;
  final String seller;
  final DateTime timestamp;
  final String? type;

  bool get isPurchase => type == 'buy' || buyer.isNotEmpty;
  bool get isSale => type == 'sell' || seller.isNotEmpty;

  factory Trade.fromJson(Map<String, dynamic> json) {
    final timestampRaw = json['timestamp'] ?? json['created_at'] ?? json['date'];
    DateTime timestamp = DateTime.now();
    if (timestampRaw != null) {
      if (timestampRaw is String) {
        timestamp = DateTime.tryParse(timestampRaw) ?? DateTime.now();
      } else if (timestampRaw is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw);
      }
    }

    String itemName = '';
    final itemVal = json['item_name'] ?? json['item'] ?? json['display_name'];
    if (itemVal is String) {
      itemName = itemVal;
    } else if (itemVal is Map) {
      itemName = (itemVal['display_name'] ?? itemVal['search_name'] ?? '') as String? ?? '';
    }

    final priceRaw = json['price'] ?? json['total'] ?? 0;
    final price = (priceRaw is num) ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;

    final quantityRaw = json['quantity'] ?? json['qty'] ?? 1;
    final quantity = (quantityRaw is int) ? quantityRaw : int.tryParse(quantityRaw.toString()) ?? 1;

    return Trade(
      id: json['id'] as int? ?? 0,
      itemName: itemName.toString(),
      price: price,
      quantity: quantity,
      buyer: json['buyer'] as String? ?? '',
      seller: json['seller'] as String? ?? '',
      timestamp: timestamp,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
        'buyer': buyer,
        'seller': seller,
        'timestamp': timestamp.toIso8601String(),
        if (type != null) 'type': type,
      };
}
