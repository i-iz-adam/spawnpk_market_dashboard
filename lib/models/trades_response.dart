import 'item.dart';
import 'pagination.dart';
import 'trade.dart';


class TradesResponse {
  const TradesResponse({
    this.item,
    required this.pagination,
    required this.trades,
  });

  final Item? item;
  final Pagination pagination;
  final List<Trade> trades;

  factory TradesResponse.fromJson(Map<String, dynamic> json) {
    Item? item;
    if (json['item'] != null) {
      item = Item.fromJson(json['item'] as Map<String, dynamic>);
    }

    Pagination pagination = const Pagination(
      limit: 50,
      page: 1,
      total: 0,
      totalPages: 0,
    );
    if (json['pagination'] != null) {
      pagination = Pagination.fromJson(json['pagination'] as Map<String, dynamic>);
    }

    final tradesList = json['trades'];
    List<Trade> trades = [];
    if (tradesList != null && tradesList is List) {
      for (final e in tradesList) {
        if (e is Map<String, dynamic>) {
          trades.add(Trade.fromJson(e));
        }
      }
    }

    return TradesResponse(item: item, pagination: pagination, trades: trades);
  }
}
