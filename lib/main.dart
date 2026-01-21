import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildLightTheme(context),
      darkTheme: _buildDarkTheme(context),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildLightTheme(BuildContext context) {
    final baseTextTheme = GoogleFonts.outfitTextTheme(
      Theme.of(context).textTheme,
    );
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF), // White surface
        onSurface: const Color(0xFF1F2937),
        primary: const Color(0xFF4CAF50),
        secondary: const Color(0xFF0175C2),
        background: const Color(0xFFF3F4F6),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      textTheme: baseTextTheme.apply(
        bodyColor: const Color(0xFF1F2937),
        displayColor: const Color(0xFF1F2937),
      ),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context) {
    final baseTextTheme = GoogleFonts.outfitTextTheme(
      Theme.of(context).textTheme,
    );
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
        primary: const Color(0xFF4CAF50),
        secondary: const Color(0xFF0175C2),
        background: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: baseTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
