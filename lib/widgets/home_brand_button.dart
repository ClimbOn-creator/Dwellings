import 'package:flutter/material.dart';

import '../screens/landing_screen.dart';
import 'brand_logo.dart';

class HomeBrandButton extends StatelessWidget {
  const HomeBrandButton({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.dark = true,
  });

  final double size;
  final bool showWordmark;
  final bool dark;

  static void open(BuildContext context) =>
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LandingScreen()),
        (_) => false,
      );

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'DwellingsIQ home',
    child: InkWell(
      onTap: () => open(context),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DwellingIqLogo(
          size: size,
          showWordmark: showWordmark,
          dark: dark,
        ),
      ),
    ),
  );
}
