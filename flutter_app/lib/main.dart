import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const KadooApp());
}

class KadooApp extends StatelessWidget {
  const KadooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kadoo - Roll Your Luck!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC2626), // Festive Gift Red
          primary: const Color(0xFFDC2626),
          secondary: const Color(0xFFE11D48),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.light).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
