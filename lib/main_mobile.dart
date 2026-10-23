import 'package:flutter/material.dart';
import 'screens/pact_messenger_page.dart';
import 'widgets/pact_mobile_surface.dart';
import 'services/backend_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendService.initialize();
  runApp(const PactMobileApp());
}

class PactMobileApp extends StatelessWidget {
  const PactMobileApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Pact',
    builder: (_, child) =>
        PactMobileSurface(child: child ?? const SizedBox.shrink()),
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6255DC),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    ),
    home: const PactMessengerPage(mobileWorkspace: true),
  );
}
