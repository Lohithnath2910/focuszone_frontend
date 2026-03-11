import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>?> fetchLatestData(String baseUrl) async {
    try {

      final response = await http.get(Uri.parse('$baseUrl/simulate-latest'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Server Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network Error: $e');
      return null;
    }
  }
}