
class HotItem {
  const HotItem({
    required this.itemName,
    required this.currentPrice,
    required this.priceChangePercent,
    required this.volumeSurge,
    required this.avgVolume,
    required this.lastTradeTime,
    required this.tradeCount,
  });

  final String itemName;
  final double currentPrice;
  final double priceChangePercent;
  final num volumeSurge; 
  final int avgVolume;
  final DateTime lastTradeTime;
  final int tradeCount;

  bool get isPriceUp => priceChangePercent > 0;
  bool get isVolumeSurge => volumeSurge > 2.0;

  factory HotItem.fromJson(Map<String, dynamic> json) {
    return HotItem(
      itemName: json['itemName'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      priceChangePercent: (json['priceChangePercent'] as num).toDouble(),
      volumeSurge: (json['volumeSurge'] as num).toDouble(),
      avgVolume: json['avgVolume'] as int,
      lastTradeTime: DateTime.parse(json['lastTradeTime'] as String),
      tradeCount: json['tradeCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'currentPrice': currentPrice,
        'priceChangePercent': priceChangePercent,
        'volumeSurge': volumeSurge,
        'avgVolume': avgVolume,
        'lastTradeTime': lastTradeTime.toIso8601String(),
        'tradeCount': tradeCount,
      };
}