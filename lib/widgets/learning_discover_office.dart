import 'dart:math' as math;

import 'package:flutter/material.dart';

const _officeSize = Size(1100, 740);
const _cabinet = Rect.fromLTWH(228, 447, 176, 203);
const _closedDrawer = Rect.fromLTWH(236, 471, 160, 73);
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

Rect discoverDrawerViewport(Size stage, double slide) => _placeInOffice(
  stage,
  Rect.lerp(
    const Rect.fromLTWH(233, 426, 169, 129),
    const Rect.fromLTWH(211, 464, 235, 169),
    slide,
  )!,
);

class DiscoverOfficePainter extends CustomPainter {
  const DiscoverOfficePainter(this.drawer);

  final double drawer;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = _officeFrame(size);
    final scale = frame.width / _officeSize.width;
    final floor = frame.top + 573 * scale;
    _fill(canvas, Offset.zero & size, const Color(0xffeee9de));
    _fill(
      canvas,
      Rect.fromLTRB(0, floor, size.width, size.height),
      const Color(0xffd0c5b1),
    );
    _fill(
      canvas,
      Rect.fromLTWH(0, floor - 8 * scale, size.width, 8 * scale),
      const Color(0xffddd4c4),
    );
    canvas.save();
    canvas.translate(frame.left, frame.top);
    canvas.scale(scale);
    _desk(canvas);
    _filingCabinet(canvas);
    _calendar(canvas);
    _pinboard(canvas);
    _computer(canvas);
    canvas.restore();
  }

  void _desk(Canvas c) {
    _poly(c, const [
      Offset(176, 624),
      Offset(940, 624),
      Offset(968, 663),
      Offset(166, 663),
    ], const Color(0xffbbb09b));
    _poly(c, const [
      Offset(875, 418),
      Offset(897, 418),
      Offset(915, 635),
      Offset(889, 637),
    ], const Color(0xff78543c));
    _poly(c, const [
      Offset(185, 418),
      Offset(213, 419),
      Offset(195, 659),
      Offset(169, 662),
    ], const Color(0xff986947));
    _poly(c, const [
      Offset(213, 419),
      Offset(225, 412),
      Offset(207, 651),
      Offset(195, 659),
    ], const Color(0xff765139));
    _poly(c, const [
      Offset(915, 420),
      Offset(945, 420),
      Offset(961, 660),
      Offset(932, 658),
    ], const Color(0xff986947));
    _fill(c, const Rect.fromLTWH(185, 423, 755, 23), const Color(0xff83593e));
    _poly(c, const [
      Offset(235, 368),
      Offset(870, 368),
      Offset(960, 415),
      Offset(152, 415),
    ], const Color(0xffc79b70));
    _poly(c, const [
      Offset(152, 415),
      Offset(960, 415),
      Offset(960, 431),
      Offset(607, 431),
      Offset(602, 425),
      Offset(584, 431),
      Offset(152, 431),
    ], const Color(0xffa4734c));
    _line(
      c,
      const Offset(160, 416),
      const Offset(948, 416),
      const Color(0xffdfb58a),
      2,
    );
    _line(
      c,
      const Offset(250, 389),
      const Offset(341, 389),
      const Color(0xffa77855),
      2,
    );
    _line(
      c,
      const Offset(737, 400),
      const Offset(809, 400),
      const Color(0xffa77855),
      2,
    );
    _line(
      c,
      const Offset(826, 404),
      const Offset(849, 408),
      const Color(0xffa77855),
      2,
    );
    _line(
      c,
      const Offset(187, 539),
      const Offset(181, 583),
      const Color(0xffc09164),
      2,
    );
    _fill(c, const Rect.fromLTWH(723, 434, 146, 29), const Color(0xffa47550));
    _fill(c, const Rect.fromLTWH(778, 445, 36, 5), const Color(0xff665141));
  }

  void _filingCabinet(Canvas c) {
    _poly(c, const [
      Offset(188, 628),
      Offset(415, 623),
      Offset(438, 645),
      Offset(229, 665),
    ], const Color(0xffb5aa96));
    _poly(c, const [
      Offset(185, 423),
      Offset(228, 447),
      Offset(228, 650),
      Offset(185, 618),
    ], discoverDrawerSide);
    _poly(c, const [
      Offset(185, 423),
      Offset(357, 410),
      Offset(404, 433),
      Offset(228, 447),
    ], discoverDrawerRim);
    c.save();
    c.translate(228, 0);
    c.transform((Matrix4.identity()..setEntry(1, 0, -.08)).storage);
    c.translate(-228, 0);
    _fill(c, _cabinet, const Color(0xff4a4d49));
    _fill(c, _closedDrawer.inflate(3), const Color(0xff282b28));
    _fill(c, const Rect.fromLTWH(233, 549, 165, 82), const Color(0xff282b28));
    _drawerFront(c, const Rect.fromLTWH(236, 552, 160, 76), 1);
    _drawerFront(c, _closedDrawer, 1 - drawer);
    c.drawCircle(
      const Offset(390, 457),
      4.5,
      Paint()..color = const Color(0xffb8b7ad),
    );
    _line(
      c,
      const Offset(390, 455),
      const Offset(390, 459),
      const Color(0xff393b38),
      1.5,
    );
    _line(
      c,
      const Offset(232, 451),
      const Offset(263, 451),
      discoverDrawerRim,
      2,
    );
    _line(
      c,
      const Offset(390, 644),
      const Offset(401, 644),
      const Color(0xffa7a394),
      2,
    );
    c.restore();
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
  }

  void _calendar(Canvas c) {
    c.save();
    c.translate(295, 134);
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
    _poly(c, const [
      Offset(694, 210),
      Offset(723, 224),
      Offset(723, 377),
      Offset(694, 389),
    ], shade);
    _fill(c, const Rect.fromLTWH(632, 210, 62, 179), beige);
    for (final y in [223.0, 244.0, 265.0]) {
      _fill(c, Rect.fromLTWH(639, y, 49, 16), shade);
      _fill(c, Rect.fromLTWH(641, y + 2, 45, 10), light);
      _fill(c, Rect.fromLTWH(645, y + 5, 31, 2), const Color(0xff8d806b));
    }
    for (var i = 0; i < 4; i++) {
      _fill(c, Rect.fromLTWH(646, 309.0 + i * 5, 35, 2), shade);
    }
    _fill(c, const Rect.fromLTWH(658, 349, 12, 17), shade);
    c.drawCircle(
      const Offset(664, 340),
      2.5,
      Paint()..color = const Color(0xff74875d),
    );
    _fill(c, const Rect.fromLTWH(467, 350, 98, 30), shade);
    _fill(c, const Rect.fromLTWH(444, 374, 144, 12), beige);
    _poly(c, const [
      Offset(426, 227),
      Offset(447, 213),
      Offset(600, 213),
      Offset(620, 227),
    ], light);
    _poly(c, const [
      Offset(426, 227),
      Offset(620, 227),
      Offset(620, 351),
      Offset(611, 361),
      Offset(426, 361),
      Offset(418, 350),
      Offset(418, 238),
    ], beige);
    _poly(c, const [
      Offset(440, 241),
      Offset(601, 241),
      Offset(608, 249),
      Offset(608, 333),
      Offset(600, 342),
      Offset(439, 342),
      Offset(431, 334),
      Offset(431, 251),
    ], const Color(0xff8f8169));
    _poly(c, const [
      Offset(442, 248),
      Offset(598, 248),
      Offset(601, 255),
      Offset(601, 329),
      Offset(594, 335),
      Offset(441, 335),
      Offset(437, 329),
      Offset(437, 255),
    ], const Color(0xff3b433d));
    _line(
      c,
      const Offset(445, 254),
      const Offset(486, 254),
      const Color(0xff566058),
      2,
    );
    _poly(c, const [
      Offset(421, 335),
      Offset(427, 342),
      Offset(425, 352),
      Offset(420, 347),
    ], shade);
    _line(
      c,
      const Offset(453, 351),
      const Offset(467, 350),
      const Color(0xffa99477),
      2,
    );
    _line(
      c,
      const Offset(602, 231),
      const Offset(615, 232),
      const Color(0xfff1e6d0),
      2,
    );
    c.drawCircle(
      const Offset(578, 350),
      2.5,
      Paint()..color = const Color(0xff74875d),
    );
    _fill(c, const Rect.fromLTWH(586, 347, 14, 5), shade);
    _poly(c, const [
      Offset(428, 383),
      Offset(610, 383),
      Offset(632, 410),
      Offset(409, 410),
    ], light);
    _fill(c, const Rect.fromLTWH(409, 410, 223, 4), shade);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 15; col++) {
        _fill(
          c,
          Rect.fromLTWH(433.0 - row * 5 + col * 11.5, 388.0 + row * 6, 8, 4),
          shade,
        );
      }
    }
    _fill(c, const Rect.fromLTWH(670, 388, 22, 19), beige);
    _line(c, const Offset(681, 388), const Offset(681, 396), shade, 1);
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
