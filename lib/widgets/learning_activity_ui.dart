import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/learning_creative_content.dart';
import 'site_copy_text.dart';
import 'site_text.dart';

const activityForest = Color(0xFF334B40);
const activityCream = Color(0xFFF5F0E5);
const activitySage = Color(0xFFE6EDE3);
const activityInk = Color(0xFF242824);
const activityRust = Color(0xFFAA523F);
const activityBody = TextStyle(fontSize: 16, height: 1.6, color: activityInk);

Widget creativeCopy(String slot, {TextStyle? style, TextAlign? textAlign}) {
  final key = 'learning.creative.$slot';
  return SiteCopyText(
    key,
    learningCreativeCopy[key]!,
    style: style ?? activityBody,
    textAlign: textAlign,
  );
}

Widget creativeValue(String slot, String value, {TextStyle? style}) {
  final key = 'learning.creative.$slot';
  return SiteText(
    learningCreativeCopy[key]!,
    contentKey: key,
    literal: true,
    templateValues: {'value0': value},
    style: style ?? activityBody,
  );
}

class AlexAvatar extends StatelessWidget {
  const AlexAvatar({super.key, this.phase = 0, this.size = 58});
  final double phase, size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size * .65,
      height: size,
      child: CustomPaint(painter: _AlexPainter(phase)),
    ),
  );
}

class _AlexPainter extends CustomPainter {
  const _AlexPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 62);
    final paint = Paint()..strokeCap = StrokeCap.round;
    final stride = math.sin(phase * math.pi * 2) * 6;
    canvas.drawOval(
      const Rect.fromLTWH(5, 56, 32, 5),
      paint..color = const Color(0x22000000),
    );
    paint
      ..color = const Color(0xFF384751)
      ..strokeWidth = 7;
    canvas.drawLine(const Offset(16, 39), Offset(15 - stride, 55), paint);
    canvas.drawLine(const Offset(25, 39), Offset(26 + stride, 55), paint);
    paint
      ..color = const Color(0xFF252F33)
      ..strokeWidth = 4;
    canvas.drawLine(Offset(12 - stride, 57), Offset(18 - stride, 57), paint);
    canvas.drawLine(Offset(24 + stride, 57), Offset(30 + stride, 57), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(11, 21, 20, 23),
        const Radius.circular(7),
      ),
      paint..color = activityForest,
    );
    paint
      ..color = const Color(0xFFCDA27C)
      ..strokeWidth = 5;
    canvas.drawLine(const Offset(12, 27), Offset(7 + stride * .4, 39), paint);
    canvas.drawLine(const Offset(30, 27), Offset(34 - stride * .4, 38), paint);
    canvas.drawCircle(
      const Offset(21, 12),
      10,
      paint..color = const Color(0xFFCEA17B),
    );
    canvas.drawArc(
      const Rect.fromLTWH(11, 1, 20, 20),
      math.pi,
      math.pi,
      true,
      paint..color = const Color(0xFF483B32),
    );
    canvas.drawCircle(const Offset(24, 13), 1, paint..color = activityInk);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AlexPainter oldDelegate) => oldDelegate.phase != phase;
}
