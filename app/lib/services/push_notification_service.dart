import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../routes/app_router.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _lastNavigatedVehicleKey = 'last_navigated_vehicle_uuid';
  static const AndroidNotificationChannel _ownerEventsChannel = AndroidNotificationChannel(
    'owner_events',
    'Owner Events',
    description: 'Owner event notifications',
    importance: Importance.defaultImportance,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _lastNavigatedVehicleUuid;
  bool _initialized = false;
  bool _channelInitialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _lastNavigatedVehicleUuid ??= await _storage.read(key: _lastNavigatedVehicleKey);

    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    await _ensureAndroidChannel();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigationMessage);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    await _handleNavigationMessage(initialMessage);
  }

  Future<void> _ensureAndroidChannel() async {
    if (!Platform.isAndroid || _channelInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_ownerEventsChannel);

    _channelInitialized = true;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final payload = _parsePayload(message);
    if (payload == null) return;

    final navigatorContext = AppRouter.navigatorKey.currentContext;
    if (navigatorContext == null) {
      debugPrint('Navigator context yok, foreground banner gösterilemedi.');
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(navigatorContext);
    if (messenger == null) {
      debugPrint('ScaffoldMessenger bulunamadı, foreground banner atlandı.');
      return;
    }

    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(payload.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(payload.body),
        ],
      ),
      action: SnackBarAction(
        label: 'Aç',
        onPressed: () {
          _navigateToVehicle(payload);
        },
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  Future<void> _handleNavigationMessage(RemoteMessage? message) async {
    final payload = _parsePayload(message);
    if (payload == null) return;

    await _navigateToVehicle(payload);
  }

  _PushPayload? _parsePayload(RemoteMessage? message) {
    if (message == null) return null;

    final data = message.data;
    final type = data['type']?.toString();
    final vehicleUuid =
        data['vehicle_uuid']?.toString() ?? data['vehicleUuid']?.toString();
    final title = data['title']?.toString();
    final body = data['body']?.toString();

    if (type == null || vehicleUuid == null || title == null || body == null) {
      debugPrint('Push payload eksik: $data');
      return null;
    }

    if (type != 'message' && type != 'location') {
      debugPrint('Geçersiz push type: $type');
      return null;
    }

    if (vehicleUuid.isEmpty) {
      debugPrint('Push payload vehicle_uuid boş: $data');
      return null;
    }

    return _PushPayload(
      type: type,
      vehicleUuid: vehicleUuid,
      title: title,
      body: body,
    );
  }

  Future<void> _navigateToVehicle(_PushPayload payload) async {
    if (!await _shouldNavigate(payload.vehicleUuid)) {
      return;
    }

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator hazır değil, HomeScreen gösterilecek.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = AppRouter.navigatorKey.currentState;
        nav?.pushNamed(AppRouter.home);
      });
      return;
    }

    navigator.pushNamed(
      AppRouter.vehicleProfile,
      arguments: {'vehicle_uuid': payload.vehicleUuid},
    );

    await _persistLastNavigated(payload.vehicleUuid);
  }

  Future<bool> _shouldNavigate(String? vehicleUuid) async {
    if (vehicleUuid == null || vehicleUuid.isEmpty) return false;

    _lastNavigatedVehicleUuid ??= await _storage.read(key: _lastNavigatedVehicleKey);

    return _lastNavigatedVehicleUuid != vehicleUuid;
  }

  Future<void> _persistLastNavigated(String vehicleUuid) async {
    _lastNavigatedVehicleUuid = vehicleUuid;
    await _storage.write(key: _lastNavigatedVehicleKey, value: vehicleUuid);
  }

  Future<void> clearLastNavigatedVehicle() async {
    _lastNavigatedVehicleUuid = null;
    await _storage.delete(key: _lastNavigatedVehicleKey);
  }
}

class _PushPayload {
  _PushPayload({
    required this.type,
    required this.vehicleUuid,
    required this.title,
    required this.body,
  });

  final String type;
  final String vehicleUuid;
  final String title;
  final String body;
}
