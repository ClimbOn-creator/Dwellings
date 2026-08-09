import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
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
    const ink = Color(0xFF10231B);
    const green = Color(0xFF1B5E45);
    const paper = Color(0xFFF5F2E9);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: green, surface: paper),
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
          fillColor: const Color(0xFFFAFAF6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDCE2DA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDCE2DA)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
