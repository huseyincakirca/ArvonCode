import 'dart:convert';
import 'package:http/http.dart' as http;
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
        print("Quick message gönderildi: ${response.body}");
        return true;
      } else {
        print("Hata kodu: ${response.statusCode}");
        print("Hata: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
      return false;
    }
  }
}
