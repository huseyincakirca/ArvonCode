import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_storage.dart';

class AuthService {
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/login');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['token'] == null) {
      throw Exception('Geçersiz yanıt');
    }

    final token = decoded['token'].toString();
    await AuthStorage.saveToken(token);
    return token;
  }

  String _parseError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}

    return 'Giriş başarısız (${response.statusCode})';
  }
}
