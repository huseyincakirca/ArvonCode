import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/message.dart';

class MessageService {
  Future<List<Message>> fetchMessages({required String token}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/messages');

    final res = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

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

    return data.map<Message>((item) {
      if (item is! Map) {
        throw Exception('Invalid message entry');
      }
      return Message.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<Message?> fetchLatestMessage({required String token}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/messages/latest');

    final res = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! Map) {
      throw Exception('Invalid response format');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);

    if (json['ok'] != true) {
      throw Exception('API error: ${json['message'] ?? 'Unknown error'}');
    }

    if (json['data'] == null) {
      return null;
    }

    final data = json['data'];

    if (data is! Map) {
      throw Exception('Invalid data payload');
    }

    return Message.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> sendCustomMessage({
    required String vehicleUuid,
    required String message,
    String? phone,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/public/message');

    final payload = {
      'vehicle_uuid': vehicleUuid,
      'message': message,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };

    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    // Burada standart JSON bekliyoruz.
    // Backend bazen HTML dönerse bu patlar; o zaman backend tarafında Accept kontrolü veya handler lazım.
    final body = jsonDecode(res.body);

    // body Map değilse hata: backend sözleşmeyi bozmuş demektir.
    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    return {
      'status': res.statusCode,
      'body': body,
    };
  }
}
