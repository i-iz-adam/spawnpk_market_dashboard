import 'item.dart';

/// Response from GET /api/dump/items
class ItemsResponse {
  const ItemsResponse({required this.items});

  final List<Item> items;

  factory ItemsResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return ItemsResponse(
      items: itemsList
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
