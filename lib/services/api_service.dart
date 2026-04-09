import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>?> fetchLatestData(String baseUrl) async {
    try {
      final sanitizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'\/$'), '');
      final response = await http
          .get(Uri.parse('$sanitizedBaseUrl/simulate-latest'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    return null;
  }
}
