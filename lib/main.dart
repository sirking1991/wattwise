import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WattWiseApp());
}

class WattWiseApp extends StatelessWidget {
  const WattWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WattWise',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2ECC71),      // Emerald green
          secondary: Color(0xFF3498DB),     // Ocean blue
          tertiary: Color(0xFFF1C40F),      // Sunny yellow
          surface: Colors.white,
          surfaceContainer: Color(0xFFF5F6FA),    // Light gray-blue
          error: Color(0xFFE74C3C),         // Coral red
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF2C3E50),     // Dark blue-gray
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF2ECC71),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF2ECC71),       // Emerald green
          secondary: Color(0xFF3498DB),      // Ocean blue
          tertiary: Color(0xFFF1C40F),       // Sunny yellow
          surface: Color(0xFF1E272E),        // Dark blue-gray
          surfaceContainer: Color(0xFF0F1419),     // Very dark blue-gray
          error: Color(0xFFE74C3C),          // Coral red
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
