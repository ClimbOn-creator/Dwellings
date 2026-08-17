import 'package:flutter/material.dart';

const brandInk = Color(0xFF050510);
const brandPurple = Color(0xFF252525);
const brandLilac = Color(0xFF9B9B98);

class AffinityLogo extends StatelessWidget {
  const AffinityLogo({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.dark = true,
  });

  final double size;
  final bool showWordmark;
  final bool dark;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/affinity-logo.png',
    width: showWordmark ? size * 2.5 : size * 1.7,
    height: size,
    fit: BoxFit.contain,
  );
}

/// The supplied mirrored Affinity artwork, cropped for use in full-width
/// footers. Its background is the same #053827 used by the footer strip, so
/// the image reads as part of the surface instead of as a separate tile.
class AffinityFooterLogo extends StatelessWidget {
  const AffinityFooterLogo({super.key, this.width = 300});

  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/affinity-footer-logo.png',
    width: width,
    fit: BoxFit.contain,
    alignment: Alignment.centerLeft,
    filterQuality: FilterQuality.high,
  );
}
