
class TopTrader {
  const TopTrader({
    required this.rank,
    required this.username,
    required this.totalVolume,
    required this.tradeCount,
    required this.avgTradeValue,
  });

  final int rank;
  final String username;
  final double totalVolume;
  final int tradeCount;
  final double avgTradeValue;

  factory TopTrader.fromJson(Map<String, dynamic> json) {
    return TopTrader(
      rank: json['rank'] as int,
      username: json['username'] as String,
      totalVolume: (json['totalVolume'] as num).toDouble(),
      tradeCount: json['tradeCount'] as int,
      avgTradeValue: (json['avgTradeValue'] as num).toDouble(),
    );
  }
}