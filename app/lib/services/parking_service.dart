import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ParkingService {
  static Future<Map<String, dynamic>> setParking({
    required String token,
    required String vehicleId,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/parking/set');

    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vehicle_id': vehicleId,
        'lat': lat,
        'lng': lng,
      }),
    );

    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>?> fetchLatestParking({
    required String token,
    required String vehicleId,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/parking/latest/${Uri.encodeComponent(vehicleId)}');

    final res = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final parsed = _parseResponse(res);
    final data = parsed['data'];

    if (data is Map<String, dynamic>) {
      final parking = data['parking'];
      if (parking == null) return null;
      if (parking is Map<String, dynamic>) {
        return parking;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>> deleteParking({
    required String token,
    required String vehicleId,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/parking/delete/${Uri.encodeComponent(vehicleId)}');

    final res = await http.delete(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _parseResponse(res);
  }

  static Map<String, dynamic> _parseResponse(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! Map) {
      throw Exception('Invalid response format');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);

    if (json['ok'] != true) {
      throw Exception(json['message'] ?? 'Unknown API error');
    }

    return json;
  }
}
