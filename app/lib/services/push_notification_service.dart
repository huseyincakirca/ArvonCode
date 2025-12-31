import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../routes/app_router.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  String? _lastNavigatedVehicleUuid;

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    _handleMessage(initialMessage);
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    final data = message.data;
    final type = data['type']?.toString();
    final vehicleUuid =
        data['vehicle_uuid']?.toString() ?? data['vehicleUuid']?.toString();

    if (type == null || vehicleUuid == null) {
      debugPrint('Push payload eksik: $data');
      return;
    }

    if (type != 'message' && type != 'location') {
      return;
    }

    if (_lastNavigatedVehicleUuid == vehicleUuid) {
      return;
    }

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator hazır değil, push navigation atlandı.');
      return;
    }

    navigator.pushNamed(
      AppRouter.vehicleProfile,
      arguments: {'vehicle_uuid': vehicleUuid},
    );

    _lastNavigatedVehicleUuid = vehicleUuid;
  }
}
