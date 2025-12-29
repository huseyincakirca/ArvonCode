import 'package:flutter/material.dart';
// import 'screens/home_screen.dart';
import 'screens/owner_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArvonCode',
      home: const OwnerDashboard(ownerToken: '1|Vpkch32fWntKpBnic0AKWjZuq62HppxpIQtPOY0pbbfd5327'),
      // home: const HomeScreen(), // 🔥 TEST KİLİDİ SÖKÜLDÜ
    );
  }
}
