import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ParkingApiException implements Exception {
  final int statusCode;
  final String body;
  final String message;

  ParkingApiException({
    required this.statusCode,
    required this.body,
    required this.message,
  });

  @override
  String toString() => 'ParkingApiException(status: $statusCode, message: $message)';
}

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
    Map<String, dynamic>? json;

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // fall through
    }

    if (res.statusCode >= 400) {
      final message =
          json != null ? (json['message']?.toString() ?? 'API error') : 'HTTP ${res.statusCode}';
      throw ParkingApiException(
        statusCode: res.statusCode,
        body: res.body,
        message: message,
      );
    }

    if (json == null) {
      throw ParkingApiException(
        statusCode: res.statusCode,
        body: res.body,
        message: 'Invalid response format',
      );
    }

    if (json['ok'] != true) {
      throw ParkingApiException(
        statusCode: res.statusCode,
        body: res.body,
        message: json['message']?.toString() ?? 'Unknown API error',
      );
    }

    return json;
  }
}
