import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class QuickMessageService {
  static Future<bool> sendQuickMessage({
    required String vehicleUuid,
    required int quickMessageId,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/public/quick-message/send',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "vehicle_uuid": vehicleUuid,
          "quick_message_id": quickMessageId,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Quick message gönderildi: ${response.body}");
        return true;
      } else {
        debugPrint("Hata kodu: ${response.statusCode}");
        debugPrint("Hata: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Bağlantı hatası: $e");
      return false;
    }
  }
}
