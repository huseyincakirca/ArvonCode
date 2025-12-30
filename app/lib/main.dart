import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'config/api_config.dart';

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
      home: const HomeScreen(),
    );
  }
}
