import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/landing_screen.dart';
import 'services/backend_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendService.initialize();
  runApp(const DwellingIqApp());
}

class DwellingIqApp extends StatelessWidget {
  const DwellingIqApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF090909);
    const purple = Color(0xFF6D28D9);
    const paper = Color(0xFFF7F7F7);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: purple, surface: paper),
      scaffoldBackgroundColor: paper,
      textTheme: GoogleFonts.dmSansTextTheme(),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DwellingIQ',
      theme: base.copyWith(
        textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
      home: const LandingScreen(),
    );
  }
}
