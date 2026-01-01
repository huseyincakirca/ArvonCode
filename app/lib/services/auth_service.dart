import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_storage.dart';
import 'push_token_service.dart';

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
    if (decoded is! Map || decoded['ok'] != true) {
      throw Exception('Giriş başarısız');
    }

    final data = decoded['data'];
    if (data is! Map || data['token'] == null) {
      throw Exception('Geçersiz yanıt: token yok');
    }

    final token = data['token'].toString();
    await AuthStorage.saveToken(token);
    await PushTokenService.instance.syncToken(token);
    return token;
  }

  Future<void> logout() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      await AuthStorage.clearToken();
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/logout');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          await PushTokenService.instance.revokeToken(token);
        } catch (e) {
          debugPrint('Push token revoke during logout failed: $e');
        }
      } else {
        debugPrint('Logout failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Logout request failed: $e');
    } finally {
      await AuthStorage.clearToken();
    }
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
