import 'dart:convert';
import 'package:http/http.dart' as http;

class PublicService {
  final String baseUrl;

  PublicService({required this.baseUrl});

  Future<Map<String, dynamic>> fetchVehicleProfile(String vehicleUuid) async {
    final url = Uri.parse('$baseUrl/public/vehicle/$vehicleUuid');

    final res = await http.get(
      url,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! Map) {
      throw Exception('Invalid JSON format');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);

    if (json['ok'] != true) {
      throw Exception('API error: ${json['message']}');
    }

    return Map<String, dynamic>.from(json['data']);
  }
}
