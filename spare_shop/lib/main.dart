import 'package:flutter/material.dart';
import 'services/local_storage.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = LocalStorage();
  await db.initDb();
  runApp(const SpareShopApp());
}

class SpareShopApp extends StatelessWidget {
  const SpareShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spare Shop',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}