import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

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
        // Optional: customize input decoration theme for consistent look
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFC9CED4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFC9CED4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1F7A4D)),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1B1F24)),
          bodyMedium: TextStyle(color: Color(0xFF5A626C)),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ------------------------------------------------------------------
// Wrapper that decides which initial screen to show
// ------------------------------------------------------------------
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    final loggedIn = await AuthService.isLoggedIn;
    if (!mounted) return;
    setState(() => _isLoggedIn = loggedIn);
  }

  // Navigate to the right screen after state is loaded
  void _navigate() {
    if (!mounted) return;
    if (_isLoggedIn) {
      // Remove explicit Navigator.push and just set state; the HomeScreen will be built
      // but we need to replace the current route.
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a placeholder while checking state
    if (_isLoggedIn == false && _isLoggedIn != true) {
      // Actually _isLoggedIn could be bool? but we treat unknown as false
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isLoggedIn) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
// ------------------------------------------------------------------
// Simple named route approach could be used, but keeping it plain.
// ------------------------------------------------------------------