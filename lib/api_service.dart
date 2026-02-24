import 'dart:convert';
import 'package:http/http.dart' as http;
import 'price_model.dart';

class ApiService {
  static const String url =
      "https://yappy-chiarra-altinv2-2dcd9f44.koyeb.app/api/prices";

  static Future<List<Price>> fetchPrices() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List pricesJson = data['data'];

      return pricesJson.map((e) => Price.fromJson(e)).toList();
    } else {
      throw Exception("API Hatası");
    }
  }
}