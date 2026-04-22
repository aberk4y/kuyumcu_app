import 'dart:convert';

import 'package:http/http.dart' as http;

import 'currency_model.dart';
import 'price_model.dart';

class ApiService {
  static const String baseUrl =
      'https://yappy-chiarra-altinv2-2dcd9f44.koyeb.app/api';

  static Future<List<Price>> fetchPrices() async {
    final response = await http.get(Uri.parse('$baseUrl/prices'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final pricesJson = data['data'] as List? ?? [];
      return pricesJson.map((item) => Price.fromJson(item)).toList();
    }

    throw Exception('Altın fiyatları alınamadı');
  }

  static Future<List<Currency>> fetchCurrencies() async {
    final response = await http.get(Uri.parse('$baseUrl/currency'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final currencyJson = data['data'] as List? ?? [];
      return currencyJson.map((item) => Currency.fromJson(item)).toList();
    }

    throw Exception('Döviz kurları alınamadı');
  }
}
