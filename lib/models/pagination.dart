
class Pagination {
  const Pagination({
    required this.limit,
    required this.page,
    required this.total,
    required this.totalPages,
  });

  final int limit;
  final int page;
  final int total;
  final int totalPages;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      limit: json['limit'] as int? ?? 50,
      page: json['page'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;
}
