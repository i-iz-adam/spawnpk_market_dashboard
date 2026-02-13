import 'package:dio/dio.dart';

import '../models/models.dart';

/// Base API URL for the market API.
const String _baseUrl =
    'https://154e845c-9ec7-4409-b6b8-743356b3bca9-00-3l96xa1wn1r90.kirk.replit.dev';

/// Service for making API calls to the market REST API.
class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = _baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 15);
  }

  final Dio _dio;

  /// Load all items. Response: {"items":[{"id":..., "display_name":..., "search_name":...}, ...]}
  Future<ItemsResponse> fetchItems() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/dump/items');
    if (response.data == null) {
      throw ApiException('Empty response from items endpoint');
    }
    return ItemsResponse.fromJson(response.data!);
  }

  /// Recent trades for an item.
  /// [itemName] should be display_name or search_name (URL-encoded).
  Future<TradesResponse> fetchTradesForItem(String itemName, {int page = 1}) async {
    final encoded = Uri.encodeComponent(itemName);
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/trades/item/$encoded',
      queryParameters: {'page': page},
    );
    if (response.data == null) {
      throw ApiException('Empty response from trades/item endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }

  /// All trades for a username.
  Future<TradesResponse> fetchTradesForUser(String username) async {
    final encoded = Uri.encodeComponent(username);
    final response = await _dio.get<Map<String, dynamic>>('/api/trades/user/$encoded');
    if (response.data == null) {
      throw ApiException('Empty response from trades/user endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }

  /// Purchases only for a username.
  Future<TradesResponse> fetchPurchasesForUser(String username) async {
    final encoded = Uri.encodeComponent(username);
    final response = await _dio.get<Map<String, dynamic>>('/api/trades/buyer/$encoded');
    if (response.data == null) {
      throw ApiException('Empty response from trades/buyer endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }

  /// Sales only. Username must use underscores (e.g. "user_name").
  Future<TradesResponse> fetchSalesForUser(String usernameWithUnderscores) async {
    final encoded = Uri.encodeComponent(usernameWithUnderscores);
    final response = await _dio.get<Map<String, dynamic>>('/api/trades/seller/$encoded');
    if (response.data == null) {
      throw ApiException('Empty response from trades/seller endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }
}

/// API call failure.
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}
