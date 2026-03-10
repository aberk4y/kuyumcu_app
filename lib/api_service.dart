import 'dart:convert';
import 'package:http/http.dart' as http;
import 'price_model.dart';

class ApiService {

  static const String baseUrl =
      "https://yappy-chiarra-altinv2-2dcd9f44.koyeb.app/api";

  /// ALTIN
  static Future<List<Price>> fetchPrices() async {

    final response = await http.get(
      Uri.parse("$baseUrl/prices"),
    );

    if (response.statusCode == 200) {

      final data = json.decode(response.body);
      final List pricesJson = data['data'];

      return pricesJson.map((e) => Price.fromJson(e)).toList();

    } else {

      throw Exception("Altın API Hatası");

    }
  }

  /// DÖVİZ
  static Future<List<dynamic>> fetchCurrencies() async {

    final response = await http.get(
      Uri.parse("$baseUrl/currency"),
    );

    if (response.statusCode == 200) {

      final data = json.decode(response.body);

      return data["data"];

    } else {

      throw Exception("Döviz API Hatası");

    }
  }

}