import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_storage.dart';

class PushTokenService {
  PushTokenService._();
  static final PushTokenService instance = PushTokenService._();

  Future<void> syncToken(String? authToken) async {
    if (authToken == null || authToken.isEmpty) return;

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/user/push-id');

      await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'push_id': fcmToken}),
      );
    } catch (e) {
      debugPrint('Push token sync failed: $e');
    }
  }

  Future<void> syncWithStoredToken() async {
    final token = await AuthStorage.getToken();
    await syncToken(token);
  }
}
