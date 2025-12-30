import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'screens/home_screen.dart';
import 'pages/auth/login_page.dart';
import 'services/auth_storage.dart';

void main() {
  // Choose global environment here (currently staging).
  const env = Environment.staging;

  // ignore: avoid_print
  print('ApiConfig environment: $env, baseUrl: ${ApiConfig.baseUrl}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArvonCode',
      home: FutureBuilder<String?>(
        future: AuthStorage.getToken(),
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
