import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/platform_side.dart';
import 'screens/deal_rooms_page.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/business_acquisition_page.dart';
import 'screens/local_network_page.dart';
import 'screens/platform_hub_page.dart';
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
      textTheme: GoogleFonts.spaceGroteskTextTheme(),
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
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
      home: _initialPage(),
    );
  }

  Widget _initialPage() {
    final module = Uri.base.queryParameters['module'];
    final side = Uri.base.queryParameters['side'] == 'business'
        ? PlatformSide.business
        : PlatformSide.property;
    return switch (module) {
      'business' => const PlatformHubPage(side: PlatformSide.business),
      'property' => const PlatformHubPage(side: PlatformSide.property),
      'business-calculator' => const BusinessAcquisitionPage(),
      'property-calculator' => const UnderwritingScreen(),
      'network' => LocalNetworkPage(side: side),
      'deal-rooms' => DealRoomsPage(initialSide: side),
      _ => const LandingScreen(),
    };
  }
}
