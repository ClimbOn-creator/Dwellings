import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const pactSurfaceGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFE9E5FF), Color(0xFFF8F8FA), Color(0xFFF5F6F8)],
  stops: [0, .45, 1],
);

/// Paint outside SafeArea; only interactive content is inset from the cutouts.
class PactMobileSurface extends StatelessWidget {
  const PactMobileSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: pactSurfaceGradient),
      child: child,
    ),
  );
}
