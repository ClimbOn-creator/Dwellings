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
    final foreground = dark ? Colors.white : brandInk;
    final mark = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(5 * scale, 5 * scale, 34 * scale, 34 * scale),
      Radius.circular(10 * scale),
    );
    canvas.drawRRect(frame, mark);
    canvas.drawLine(
      Offset(14 * scale, 29 * scale),
      Offset(22 * scale, 16 * scale),
      mark,
    );
    canvas.drawLine(
      Offset(22 * scale, 16 * scale),
      Offset(30 * scale, 29 * scale),
      mark,
    );
    canvas.drawLine(
      Offset(14 * scale, 29 * scale),
      Offset(30 * scale, 29 * scale),
      mark,
    );
    final accent = Paint()..color = brandPurple;
    canvas.drawCircle(Offset(33.5 * scale, 10.5 * scale), 2.6 * scale, accent);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
