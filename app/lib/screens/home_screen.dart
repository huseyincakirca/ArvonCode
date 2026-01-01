import 'package:flutter/material.dart';

import '../routes/app_router.dart';
import '../services/push_notification_service.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    PushNotificationService.instance.clearLastNavigatedVehicle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ArvonCode')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text('QR Tara'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanScreen(
                      enableCamera: true,
                      enableNfc: false,
                      title: 'QR Tara',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text('NFC Tara'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanScreen(
                      enableCamera: false,
                      enableNfc: true,
                      title: 'NFC Tara',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
