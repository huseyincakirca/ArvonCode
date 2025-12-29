import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LocationService {
  static Future<Map<String, dynamic>> saveLocation({
    required String vehicleUuid,
    required double lat,
    required double lng,
    required double accuracy,
    required String source,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/public/location/save',
    );

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'vehicle_uuid': vehicleUuid,
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'source': source,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> fetchOwnerLocations({
    required String token,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/locations');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid response format');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);

    if (json['ok'] != true) {
      throw Exception('API error: ${json['message'] ?? 'Unknown error'}');
    }

    final data = json['data'];

    if (data is! List) {
      throw Exception('Invalid data payload');
    }

    return data.map<Map<String, dynamic>>((item) {
      if (item is! Map) {
        throw Exception('Invalid location entry');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
