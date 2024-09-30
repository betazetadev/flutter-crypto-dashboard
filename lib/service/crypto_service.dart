import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoService {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

    Future<List<double>> getCryptoPrices(String coinId, String days) async {
      try {
        final url = Uri.parse('$baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<double> prices = List<double>.from(data['prices'].map((priceData) => priceData[1]));
          return prices;
        } else {
          throw Exception('Failed to load data: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error fetching data: $e');
      }
    }
}
