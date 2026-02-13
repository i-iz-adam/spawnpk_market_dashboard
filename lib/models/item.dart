/// Model for an item from the items dump API.
class Item {
  const Item({
    required this.id,
    required this.displayName,
    required this.searchName,
  });

  final int id;
  final String displayName;
  final String searchName;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      displayName: json['display_name'] as String? ?? '',
      searchName: json['search_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'search_name': searchName,
      };
}
