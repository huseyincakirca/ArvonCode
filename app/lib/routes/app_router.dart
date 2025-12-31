import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/vehicle_profile_screen.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const String vehicleProfile = '/vehicle-profile';
  static const String home = '/home';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case vehicleProfile:
        final args = settings.arguments;
        String? vehicleUuid;

        if (args is Map && args['vehicle_uuid'] != null) {
          vehicleUuid = args['vehicle_uuid']?.toString();
        } else if (args is Map && args['vehicleUuid'] != null) {
          vehicleUuid = args['vehicleUuid']?.toString();
        }

        if (vehicleUuid == null || vehicleUuid.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Geçersiz push payload')),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => VehicleProfileScreen(vehicleUuid: vehicleUuid!),
        );
      default:
        return null;
    }
  }
}
