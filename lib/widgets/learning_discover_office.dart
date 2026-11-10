import 'dart:math' as math;

import 'package:flutter/material.dart';

const _officeSize = Size(1100, 740);
const _cabinet = Rect.fromLTWH(185, 428, 211, 225);
const _closedDrawer = Rect.fromLTWH(195, 450, 191, 82);
const discoverDrawerFace = Color(0xff575a58);
const discoverDrawerSide = Color(0xff3f4240);
const discoverDrawerRim = Color(0xff848781);

Rect _officeFrame(Size stage) {
  final scale = math.min(
    stage.width / _officeSize.width,
    stage.height / _officeSize.height,
  );
  return Rect.fromCenter(
    center: stage.center(Offset.zero),
    width: _officeSize.width * scale,
    height: _officeSize.height * scale,
  );
}

Rect _placeInOffice(Size stage, Rect bounds) {
  final frame = _officeFrame(stage);
  final scale = frame.width / _officeSize.width;
  return Rect.fromLTWH(
    bounds.left * scale,
    bounds.top * scale,
    bounds.width * scale,
    bounds.height * scale,
  ).shift(frame.topLeft);
}

Rect discoverCabinetHitArea(Size stage) => _placeInOffice(
  stage,
  Rect.fromLTRB(
    _cabinet.left - 31,
    _cabinet.top - 12,
    _cabinet.right + 12,
    _cabinet.bottom + 34,
  ),
);

Rect discoverDrawerFront(Size stage, double slide) =>
    _placeInOffice(stage, _closedDrawer.shift(Offset(0, slide * 72)));

double discoverDeskUnderside(Size stage) => _placeInOffice(stage, _cabinet).top;

class DiscoverOfficePainter extends CustomPainter {
  const DiscoverOfficePainter(this.drawer);

  final double drawer;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = _officeFrame(size);
    final scale = frame.width / _officeSize.width;
    final floor = frame.top + 573 * scale;
    _fill(canvas, Offset.zero & size, const Color(0xfffdfdfc));
    _fill(
      canvas,
      Rect.fromLTRB(0, floor, size.width, size.height),
      const Color(0xfff0efed),
    );
    _fill(
      canvas,
      Rect.fromLTWH(0, floor - 8 * scale, size.width, 8 * scale),
      const Color(0xffe8e7e4),
    );
    canvas.save();
    canvas.translate(frame.left, frame.top);
    canvas.scale(scale);
    _poly(canvas, const [
      Offset(176, 624),
      Offset(940, 624),
      Offset(968, 663),
      Offset(166, 663),
    ], const Color(0xffe2e1dd));
    _filingCabinet(canvas);
    _desk(canvas);
    _calendar(canvas);
    _pinboard(canvas);
    _computer(canvas);
    _lamp(canvas);
    canvas.restore();
  }

  void _desk(Canvas c) {
    _poly(c, const [
      Offset(875, 418),
      Offset(897, 418),
      Offset(915, 635),
      Offset(889, 637),
    ], const Color(0xff343534));
    _poly(c, const [
      Offset(915, 420),
      Offset(945, 420),
      Offset(961, 660),
      Offset(932, 658),
    ], const Color(0xff282929));
    _fill(c, const Rect.fromLTWH(185, 423, 755, 23), const Color(0xff242525));
    _poly(c, const [
      Offset(235, 368),
      Offset(870, 368),
      Offset(960, 415),
      Offset(152, 415),
    ], const Color(0xff414242));
    _poly(c, const [
      Offset(152, 415),
      Offset(960, 415),
      Offset(960, 431),
      Offset(607, 431),
      Offset(602, 425),
      Offset(584, 431),
      Offset(152, 431),
    ], const Color(0xff242525));
    _line(
      c,
      const Offset(160, 416),
      const Offset(948, 416),
      const Color(0xff616262),
      2,
    );
    _line(
      c,
      const Offset(250, 389),
      const Offset(341, 389),
      const Color(0xff545555),
      2,
    );
    _line(
      c,
      const Offset(737, 400),
      const Offset(809, 400),
      const Color(0xff545555),
      2,
    );
    _line(
      c,
      const Offset(826, 404),
      const Offset(849, 408),
      const Color(0xff545555),
      2,
    );
    _fill(c, const Rect.fromLTWH(723, 434, 146, 29), const Color(0xff353636));
    _fill(c, const Rect.fromLTWH(778, 445, 36, 5), const Color(0xff222323));
  }

  void _filingCabinet(Canvas c) {
    _poly(c, const [
      Offset(396, 428),
      Offset(435, 413),
      Offset(435, 621),
      Offset(396, 653),
    ], discoverDrawerSide);
    _poly(c, const [
      Offset(404, 477),
      Offset(426, 468),
      Offset(429, 483),
      Offset(419, 485),
      Offset(416, 491),
      Offset(404, 495),
    ], const Color(0xffa18b64));
    _line(
      c,
      const Offset(408, 483),
      const Offset(423, 477),
      const Color(0xff6f654f),
      2,
    );
    _poly(c, const [
      Offset(407, 518),
      Offset(424, 509),
      Offset(428, 517),
      Offset(422, 528),
      Offset(413, 531),
      Offset(407, 526),
    ], const Color(0xff84988f));
    _fill(c, _cabinet, const Color(0xff373938));
    _fill(c, _closedDrawer.inflate(3), const Color(0xff222423));
    _fill(c, const Rect.fromLTWH(192, 536, 197, 97), const Color(0xff222423));
    _drawerFront(c, const Rect.fromLTWH(195, 539, 191, 91), 1);
    _drawerFront(c, _closedDrawer, 1 - drawer);
    c.drawCircle(
      const Offset(376, 442),
      4,
      Paint()..color = const Color(0xffb8b7ad),
    );
    _line(
      c,
      const Offset(376, 440),
      const Offset(376, 444),
      const Color(0xff393b38),
      1.5,
    );
    _line(
      c,
      const Offset(190, 642),
      const Offset(205, 642),
      discoverDrawerRim,
      2,
    );
  }

  void _drawerFront(Canvas c, Rect rect, double alpha) {
    _fill(c, rect, discoverDrawerFace.withValues(alpha: alpha));
    final x = rect.center.dx;
    final y = rect.top;
    _fill(
      c,
      Rect.fromLTWH(x - 24, y + 9, 48, 17),
      const Color(0xff30332f).withValues(alpha: alpha),
    );
    _fill(
      c,
      Rect.fromLTWH(x - 21, y + 12, 42, 11),
      const Color(0xffe9e2d2).withValues(alpha: alpha),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 18, y + 40, 36, 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xff2c2f2b).withValues(alpha: alpha),
    );
    _line(
      c,
      Offset(x - 13, y + 41),
      Offset(x + 13, y + 41),
      discoverDrawerRim.withValues(alpha: alpha),
      1,
    );
    _line(
      c,
      Offset(rect.left + 8, rect.bottom - 8),
      Offset(rect.left + 33, rect.bottom - 11),
      const Color(0xff7a7c72).withValues(alpha: alpha),
      2,
    );
    final left = rect.left;
    _poly(
      c,
      [
        Offset(left + 11, y + 31),
        Offset(left + 34, y + 29),
        Offset(left + 35, y + 42),
        Offset(left + 28, y + 41),
        Offset(left + 25, y + 45),
        Offset(left + 11, y + 46),
      ],
      (rect == _closedDrawer
              ? const Color(0xffab827b)
              : const Color(0xff84988f))
          .withValues(alpha: alpha),
    );
    _line(
      c,
      Offset(left + 15, y + 36),
      Offset(left + 29, y + 35),
      const Color(0xffe0bfb0).withValues(alpha: alpha),
      2,
    );
    _poly(c, [
      Offset(rect.right - 34, y + 51),
      Offset(rect.right - 11, y + 54),
      Offset(rect.right - 12, y + 63),
      Offset(rect.right - 20, y + 63),
      Offset(rect.right - 23, y + 60),
      Offset(rect.right - 35, y + 61),
    ], const Color(0xffa8a188).withValues(alpha: alpha));
  }

  void _calendar(Canvas c) {
    c.save();
    c.translate(271, 128);
    c.rotate(-.065);
    _fill(c, const Rect.fromLTWH(5, 5, 141, 152), const Color(0xffd5cbbb));
    _poly(c, const [
      Offset(0, 0),
      Offset(141, 0),
      Offset(141, 136),
      Offset(121, 154),
      Offset(89, 151),
      Offset(77, 154),
      Offset(0, 154),
    ], const Color(0xfff6eed8));
    _fill(c, const Rect.fromLTWH(0, 0, 141, 33), const Color(0xffaa705c));
    _poly(c, const [
      Offset(121, 154),
      Offset(121, 136),
      Offset(141, 136),
    ], const Color(0xffdfcdb0));
    _fill(c, const Rect.fromLTWH(20, -6, 5, 14), const Color(0xff716857));
    _fill(c, const Rect.fromLTWH(116, -6, 5, 14), const Color(0xff716857));
    _text(
      c,
      'NOVEMBER',
      const Offset(70, 17),
      15,
      const Color(0xfffff5e5),
      FontWeight.w700,
    );
    for (var i = 0; i < 30; i++) {
      _text(
        c,
        '${i + 1}',
        Offset(15.0 + i % 7 * 18, 52.0 + (i ~/ 7) * 17),
        9,
        const Color(0xff685c49),
        FontWeight.w500,
      );
    }
    _line(
      c,
      const Offset(10, 138),
      const Offset(47, 138),
      const Color(0xffd2bda0),
      1,
    );
    c.restore();
  }

  void _pinboard(Canvas c) {
    _fill(c, const Rect.fromLTWH(756, 169, 171, 105), const Color(0xffd4c7b3));
    _fill(c, const Rect.fromLTWH(751, 164, 171, 105), const Color(0xff8e6449));
    _fill(c, const Rect.fromLTWH(757, 170, 159, 93), const Color(0xffbc9468));
    _poly(c, const [
      Offset(770, 190),
      Offset(811, 183),
      Offset(819, 237),
      Offset(776, 243),
    ], const Color(0xffe9d7ad));
    _poly(c, const [
      Offset(822, 194),
      Offset(869, 201),
      Offset(863, 249),
      Offset(817, 242),
    ], const Color(0xffe4ddd0));
    _poly(c, const [
      Offset(873, 182),
      Offset(901, 185),
      Offset(899, 219),
      Offset(870, 216),
    ], const Color(0xffc7cdb9));
    for (final pin in const [
      Offset(791, 192),
      Offset(845, 203),
      Offset(886, 188),
    ]) {
      c.drawCircle(pin, 3, Paint()..color = const Color(0xff9a5b4e));
    }
  }

  void _computer(Canvas c) {
    const beige = Color(0xffd8c9a9);
    const light = Color(0xffebdfc4);
    const shade = Color(0xffb2a184);
    _fill(c, const Rect.fromLTWH(621, 247, 65, 141), shade);
    _fill(c, const Rect.fromLTWH(624, 249, 59, 135), beige);
    for (final y in [258.0, 277.0, 296.0]) {
      _fill(c, Rect.fromLTWH(631, y, 45, 14), shade);
      _fill(c, Rect.fromLTWH(633, y + 2, 41, 9), light);
      _fill(c, Rect.fromLTWH(638, y + 4, 27, 2), const Color(0xff8d806b));
    }
    for (var i = 0; i < 4; i++) {
      _fill(c, Rect.fromLTWH(637, 322.0 + i * 5, 33, 2), shade);
    }
    _fill(c, const Rect.fromLTWH(651, 352, 9, 15), shade);
    c.drawCircle(
      const Offset(655, 346),
      2,
      Paint()..color = const Color(0xff74875d),
    );
    _fill(c, const Rect.fromLTWH(493, 351, 75, 26), shade);
    _fill(c, const Rect.fromLTWH(473, 371, 115, 12), beige);
    _poly(c, const [
      Offset(454, 254),
      Offset(604, 254),
      Offset(613, 263),
      Offset(613, 351),
      Offset(604, 360),
      Offset(454, 360),
      Offset(445, 351),
      Offset(445, 263),
    ], beige);
    _line(c, const Offset(455, 257), const Offset(603, 257), light, 2);
    _poly(c, const [
      Offset(462, 266),
      Offset(596, 266),
      Offset(603, 273),
      Offset(603, 337),
      Offset(596, 344),
      Offset(462, 344),
      Offset(455, 337),
      Offset(455, 273),
    ], const Color(0xff8f8169));
    final screen = Path()
      ..addPolygon(const [
        Offset(469, 273),
        Offset(589, 273),
        Offset(596, 280),
        Offset(596, 330),
        Offset(589, 337),
        Offset(469, 337),
        Offset(462, 330),
        Offset(462, 280),
      ], true);
    c.drawPath(screen, Paint()..color = const Color(0xff17251c));
    c.save();
    c.clipPath(screen);
    for (var y = 275.0; y < 338; y += 3) {
      _line(c, Offset(461, y), Offset(597, y), const Color(0xff253a2a), .6);
    }
    final terminal = TextPainter(
      text: const TextSpan(
        text:
            'PACT SYSTEMS   V1.0\n> DISCOVER TERMINAL\n  FILE INDEX ONLINE\n> _',
        style: TextStyle(
          color: Color(0xff9adb7b),
          fontFamily: 'monospace',
          fontSize: 8,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 124);
    terminal.paint(c, const Offset(471, 280));
    terminal.dispose();
    c.restore();
    _line(c, const Offset(456, 349), const Offset(468, 351), shade, 2);
    c.drawCircle(
      const Offset(580, 350),
      2,
      Paint()..color = const Color(0xff7b9b5f),
    );
    _fill(c, const Rect.fromLTWH(588, 347, 13, 5), shade);

    _poly(c, const [
      Offset(449, 387),
      Offset(607, 387),
      Offset(624, 409),
      Offset(433, 409),
    ], light);
    _fill(c, const Rect.fromLTWH(433, 409, 191, 4), shade);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 15; col++) {
        _fill(
          c,
          Rect.fromLTWH(453.0 - row * 4 + col * 9.7, 391.0 + row * 5, 7, 3),
          shade,
        );
      }
    }
    _poly(c, const [
      Offset(652, 388),
      Offset(702, 388),
      Offset(716, 413),
      Offset(642, 413),
    ], const Color(0xff6d7874));
    _poly(c, const [
      Offset(671, 391),
      Offset(687, 391),
      Offset(691, 396),
      Offset(691, 405),
      Offset(688, 407),
      Offset(671, 407),
      Offset(668, 404),
      Offset(668, 396),
    ], beige);
    _line(c, const Offset(680, 391), const Offset(680, 398), shade, 1);
  }

  void _lamp(Canvas c) {
    final neck = Path()
      ..moveTo(252, 387)
      ..cubicTo(251, 361, 260, 328, 282, 318);
    c.drawPath(
      neck,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xff858277),
    );
    _poly(c, const [
      Offset(234, 382),
      Offset(269, 382),
      Offset(278, 392),
      Offset(226, 392),
    ], const Color(0xff82624e));
    _fill(c, const Rect.fromLTWH(226, 392, 52, 6), const Color(0xff584439));
    _poly(c, const [
      Offset(274, 312),
      Offset(286, 303),
      Offset(296, 309),
      Offset(300, 319),
      Offset(311, 328),
      Offset(290, 342),
      Offset(283, 327),
    ], const Color(0xff8f6c53));
    _poly(c, const [
      Offset(290, 342),
      Offset(311, 328),
      Offset(308, 334),
      Offset(294, 343),
    ], const Color(0xffd7bc91));
    _line(
      c,
      const Offset(278, 314),
      const Offset(284, 309),
      const Color(0xffb49374),
      2,
    );
  }

  @override
  bool shouldRepaint(DiscoverOfficePainter oldDelegate) =>
      oldDelegate.drawer != drawer;
}

void _fill(Canvas c, Rect rect, Color color) =>
    c.drawRect(rect, Paint()..color = color);

void _poly(Canvas c, List<Offset> points, Color color) =>
    c.drawPath(Path()..addPolygon(points, true), Paint()..color = color);

void _line(Canvas c, Offset a, Offset b, Color color, double width) =>
    c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width,
    );

void _text(
  Canvas c,
  String label,
  Offset center,
  double size,
  Color color,
  FontWeight weight,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, center - Offset(painter.width / 2, painter.height / 2));
  painter.dispose();
}
