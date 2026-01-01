import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_storage.dart';

class PushTokenService {
  PushTokenService._();
  static final PushTokenService instance = PushTokenService._();

  static const _lastSyncedTokenKey = 'last_synced_push_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _pendingFcmToken;
  String? _lastSyncedToken;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _lastSyncedToken = await _storage.read(key: _lastSyncedTokenKey);

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _pendingFcmToken = token;
      final authToken = await AuthStorage.getToken();
      if (authToken != null && authToken.isNotEmpty) {
        await _syncTokenWithServer(authToken, token);
      }
    });
  }

  Future<void> syncToken(String? authToken) async {
    await init();

    if (authToken == null || authToken.isEmpty) return;

    final fcmToken = _pendingFcmToken ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    await _syncTokenWithServer(authToken, fcmToken);
  }

  Future<void> syncWithStoredToken() async {
    final token = await AuthStorage.getToken();
    await syncToken(token);
  }

  Future<void> revokeToken(String? authToken) async {
    await init();
    if (authToken == null || authToken.isEmpty) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/user/push-id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'push_id': null}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Push token revoke failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Push token revoke failed: $e');
    } finally {
      await _clearCachedToken();
    }
  }

  Future<void> _syncTokenWithServer(String authToken, String fcmToken) async {
    if (_lastSyncedToken == fcmToken) {
      _pendingFcmToken = null;
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/user/push-id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'push_id': fcmToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastSyncedToken = fcmToken;
        _pendingFcmToken = null;
        await _storage.write(key: _lastSyncedTokenKey, value: fcmToken);
      } else {
        debugPrint('Push token sync failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Push token sync failed: $e');
    }
  }

  Future<void> _clearCachedToken() async {
    _pendingFcmToken = null;
    _lastSyncedToken = null;
    await _storage.delete(key: _lastSyncedTokenKey);
  }
}
