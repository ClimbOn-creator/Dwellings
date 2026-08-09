import 'package:flutter/material.dart';

const brandInk = Color(0xFF050510);
const brandPurple = Color(0xFF7657FF);
const brandLilac = Color(0xFFBCAEFF);

class DwellingIqLogo extends StatelessWidget {
  const DwellingIqLogo({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.dark = true,
  });

  final double size;
  final bool showWordmark;
  final bool dark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LogoPainter(dark: dark)),
      ),
      if (showWordmark) ...[
        SizedBox(width: size * .28),
        Text(
          'DWELLINGS',
          style: TextStyle(
            color: dark ? Colors.white : brandInk,
            fontSize: size * .29,
            fontWeight: FontWeight.w800,
            letterSpacing: size * .027,
          ),
        ),
        Text(
          'IQ',
          style: TextStyle(
            color: brandPurple,
            fontSize: size * .29,
            fontWeight: FontWeight.w900,
            letterSpacing: size * .027,
          ),
        ),
      ],
    ],
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 44;
    final background = Paint()
      ..color = dark ? Colors.white : brandInk
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(14 * scale)),
      background,
    );

    final ink = dark ? brandInk : Colors.white;
    final structure = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final body = Path()
      ..moveTo(13 * scale, 11 * scale)
      ..lineTo(21 * scale, 11 * scale)
      ..cubicTo(
        30 * scale,
        11 * scale,
        34 * scale,
        15.5 * scale,
        34 * scale,
        22 * scale,
      )
      ..cubicTo(
        34 * scale,
        28.5 * scale,
        30 * scale,
        33 * scale,
        21 * scale,
        33 * scale,
      )
      ..lineTo(13 * scale, 33 * scale)
      ..close();
    canvas.drawPath(body, structure);

    final doorway = Paint()
      ..color = brandPurple
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(17 * scale, 22 * scale, 7 * scale, 11 * scale),
        Radius.circular(2.2 * scale),
      ),
      doorway,
    );

    final node = Paint()
      ..color = brandLilac
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(31 * scale, 12 * scale), 3.2 * scale, node);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
