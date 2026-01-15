// lib/services/no_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NoService {
  static const _baseUrl = 'https://naas.isalman.dev/no';

  Future<String> getNoReason() async {
    final uri = Uri.parse(_baseUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['reason'] as String? ??
          'No reason provided, but… it’s still a no 😅';
    } else {
      throw Exception(
        'Failed to fetch no reason (status: ${response.statusCode})',
      );
    }
  }
}