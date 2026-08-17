import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/platform_side.dart';
import 'screens/deal_rooms_page.dart';
import 'screens/business_acquisition_page.dart';
import 'screens/local_network_page.dart';
import 'screens/member_workspace_pages.dart';
import 'screens/acquisition_support_page.dart';
import 'services/backend_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendService.initialize();
  await AcquisitionFoundation.load();
  runApp(const AffinityApp());
}

class AffinityApp extends StatelessWidget {
  const AffinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF090909);
    const blue = Color(0xFF252525);
    const paper = Color(0xFFF7F7F7);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: blue, surface: paper)
          .copyWith(
            primary: const Color(0xFF252525),
            secondary: const Color(0xFF6C6A66),
          ),
      scaffoldBackgroundColor: paper,
      textTheme: GoogleFonts.spaceGroteskTextTheme(),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Affinity',
      theme: base.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _AffinityPageTransitionsBuilder(),
            TargetPlatform.iOS: _AffinityPageTransitionsBuilder(),
            TargetPlatform.macOS: _AffinityPageTransitionsBuilder(),
            TargetPlatform.windows: _AffinityPageTransitionsBuilder(),
            TargetPlatform.linux: _AffinityPageTransitionsBuilder(),
            TargetPlatform.fuchsia: _AffinityPageTransitionsBuilder(),
          },
        ),
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
      'business' => const AcquisitionSupportPage(),
      'property' => const AcquisitionSupportPage(),
      'business-calculator' => const BusinessAcquisitionPage(),
      'property-calculator' => const AcquisitionSupportPage(),
      'network' => LocalNetworkPage(side: side),
      'deal-rooms' => const DealRoomsPage(initialSide: PlatformSide.business),
      'member-leads' => const MemberLeadInboxPage(),
      'email-composer' => const MemberEmailComposerPage(),
      'newsletter-builder' => const MemberNewsletterBuilderPage(),
      'landing' => const AcquisitionSupportPage(),
      'acquisition-support' => const AcquisitionSupportPage(),
      _ => const AcquisitionSupportPage(),
    };
  }
}

class _AffinityPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AffinityPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
