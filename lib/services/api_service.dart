import 'package:dio/dio.dart';

import '../models/models.dart';


const String _baseUrl =
    'https://famous-evie-dev-wizard-7bb55eaa.koyeb.app';


class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = _baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 15);
  }

  final Dio _dio;


  Future<ItemsResponse> fetchItems() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/dump/items');
    if (response.data == null) {
      throw ApiException('Empty response from items endpoint');
    }
    return ItemsResponse.fromJson(response.data!);
  }



  Future<TradesResponse> fetchTradesForItem(String itemName, {int page = 1}) async {
    final encoded = Uri.encodeComponent(itemName);
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/trades/item/$encoded',
      queryParameters: {'page': page},
    );
    print("Searching for item at [${response.realUri.path}]");
    if (response.data == null) {
      throw ApiException('Empty response from trades/item endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }


  Future<TradesResponse> fetchTradesForUser(String username) async {
    final encoded = Uri.encodeComponent(username);
    final response = await _dio.get<Map<String, dynamic>>('/api/trades/user/$encoded');
    if (response.data == null) {
      throw ApiException('Empty response from trades/user endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }


  Future<TradesResponse> fetchPurchasesForUser(String username) async {
    final encoded = Uri.encodeComponent(username);
    final response = await _dio.get<Map<String, dynamic>>('/api/trades/buyer/$encoded');
    if (response.data == null) {
      throw ApiException('Empty response from trades/buyer endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }


  Future<TradesResponse> fetchSalesForUser(String usernameWithUnderscores) async {
    final encoded = Uri.encodeComponent(usernameWithUnderscores);
    final response = await _dio.get<Map<String, dynamic>>('/api/trades/seller/$encoded');
    if (response.data == null) {
      throw ApiException('Empty response from trades/seller endpoint');
    }
    return TradesResponse.fromJson(response.data!);
  }
}


class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}
