import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'pages/auth/login_page.dart';
import 'routes/app_router.dart';
import 'screens/home_screen.dart';
import 'services/auth_storage.dart';
import 'services/push_notification_service.dart';
import 'services/push_token_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const env = Environment.staging;
  debugPrint('ApiConfig environment: $env, baseUrl: ${ApiConfig.baseUrl}');

  final storedToken = await AuthStorage.getToken();
  await PushTokenService.instance.syncToken(storedToken);

  runApp(MyApp(initialToken: storedToken));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture =
        widget.initialToken != null ? Future.value(widget.initialToken) : AuthStorage.getToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.init();
      PushTokenService.instance.syncWithStoredToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      title: 'ArvonCode',
      home: FutureBuilder<String?>(
        future: _tokenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final token = snapshot.data;
          final hasToken = token != null && token.isNotEmpty;

          return hasToken ? const HomeScreen() : const LoginPage();
        },
      ),
    );
  }
}
