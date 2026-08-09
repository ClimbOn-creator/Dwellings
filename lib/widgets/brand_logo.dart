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
    final housePaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final house = Path()
      ..moveTo(10 * scale, 23 * scale)
      ..lineTo(22 * scale, 12 * scale)
      ..lineTo(34 * scale, 23 * scale)
      ..lineTo(34 * scale, 34 * scale)
      ..lineTo(10 * scale, 34 * scale)
      ..close();
    canvas.drawPath(house, housePaint);

    final door = Paint()
      ..color = brandPurple
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18 * scale, 24 * scale, 8 * scale, 10 * scale),
        Radius.circular(2 * scale),
      ),
      door,
    );

    final connection = Paint()
      ..color = brandLilac
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(28 * scale, 17.5 * scale),
      Offset(34.5 * scale, 11 * scale),
      connection,
    );

    final node = Paint()
      ..color = brandLilac
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(36 * scale, 9.5 * scale), 3.6 * scale, node);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
