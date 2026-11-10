import 'dart:math' as math;

import 'package:flutter/material.dart';

const _officeSize = Size(1100, 760);

Rect discoverOfficeFrame(Size stage) {
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

Rect discoverOfficeFileBox(Size stage) {
  final frame = discoverOfficeFrame(stage);
  final scale = frame.width / _officeSize.width;
  return Rect.fromLTWH(
    234 * scale,
    475 * scale,
    210 * scale,
    165 * scale,
  ).shift(frame.topLeft);
}

class DiscoverOfficePainter extends CustomPainter {
  const DiscoverOfficePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final frame = discoverOfficeFrame(size);
    final floor = frame.top + frame.height * 575 / _officeSize.height;
    _wash(canvas, Rect.fromLTRB(0, 0, size.width, floor), const [
      Color(0xffe7e4dc),
      Color(0xfff4f0e6),
      Color(0xffd9d5c9),
    ]);
    _wash(canvas, Rect.fromLTRB(0, floor, size.width, size.height), const [
      Color(0xffa09786),
      Color(0xffc7bdac),
    ]);
    _wash(canvas, Rect.fromLTWH(0, floor - 8, size.width, 10), const [
      Color(0xffe5dfd2),
      Color(0xffc3bbae),
    ]);

    canvas.save();
    canvas.translate(frame.left, frame.top);
    canvas.scale(frame.width / _officeSize.width);
    _drawDesk(canvas);
    _drawCalendar(canvas);
    _drawPinboard(canvas);
    _drawComputer(canvas);
    canvas.restore();
  }

  void _drawDesk(Canvas canvas) {
    _shadow(canvas, const Rect.fromLTWH(143, 616, 813, 60), blur: 24);
    _polygon(canvas, const [
      Offset(801, 423),
      Offset(824, 425),
      Offset(836, 620),
      Offset(811, 623),
    ], const Color(0xff59483d));
    _polygon(canvas, const [
      Offset(243, 420),
      Offset(268, 420),
      Offset(259, 620),
      Offset(235, 622),
    ], const Color(0xff635044));
    _polygon(canvas, const [
      Offset(180, 438),
      Offset(210, 438),
      Offset(200, 658),
      Offset(169, 662),
    ], const Color(0xff795e4a));
    _polygon(canvas, const [
      Offset(210, 438),
      Offset(224, 428),
      Offset(211, 652),
      Offset(200, 658),
    ], const Color(0xff4c3d33));
    _polygon(canvas, const [
      Offset(889, 438),
      Offset(919, 438),
      Offset(932, 662),
      Offset(901, 658),
    ], const Color(0xff775c47));
    _polygon(canvas, const [
      Offset(919, 438),
      Offset(932, 429),
      Offset(944, 654),
      Offset(932, 662),
    ], const Color(0xff504033));
    _wash(canvas, const Rect.fromLTWH(200, 446, 707, 28), const [
      Color(0xff6f5141),
      Color(0xff553e33),
    ]);
    _wash(canvas, const Rect.fromLTWH(666, 448, 211, 51), const [
      Color(0xffa78062),
      Color(0xff866149),
    ], radius: 2);
    _rounded(
      canvas,
      const Rect.fromLTWH(746, 473, 52, 6),
      3,
      const Color(0xff503e33),
    );
    _rounded(
      canvas,
      const Rect.fromLTWH(746, 471, 52, 3),
      1,
      const Color(0xffc6ab86),
    );

    const surface = [
      Offset(228, 379),
      Offset(876, 379),
      Offset(949, 439),
      Offset(151, 439),
    ];
    final top = Path()..addPolygon(surface, true);
    canvas.save();
    canvas.clipPath(top);
    _wash(canvas, const Rect.fromLTWH(150, 379, 801, 61), const [
      Color(0xffae8765),
      Color(0xffcaa782),
      Color(0xffba936d),
    ]);
    final grain = math.Random(35);
    for (var i = 0; i < 92; i++) {
      final x = 154 + grain.nextDouble() * 793;
      final y = 381 + grain.nextDouble() * 58;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 12 + grain.nextDouble() * 180, y + .8),
        Paint()
          ..strokeWidth = .7
          ..color = const Color(
            0xff65402d,
          ).withValues(alpha: .035 + grain.nextDouble() * .10),
      );
    }
    canvas.restore();
    _wash(canvas, const Rect.fromLTWH(151, 439, 798, 13), const [
      Color(0xffd1aa81),
      Color(0xff956d50),
      Color(0xff75553f),
    ], radius: 1.5);
  }

  void _drawCalendar(Canvas canvas) {
    _paperShadow(canvas, const Rect.fromLTWH(270, 107, 142, 169), 3);
    _wash(canvas, const Rect.fromLTWH(270, 107, 142, 168), const [
      Color(0xfffcf9ef),
      Color(0xffece8da),
    ], radius: 3);
    _wash(canvas, const Rect.fromLTWH(270, 107, 142, 37), const [
      Color(0xffa16453),
      Color(0xff844f42),
    ], radius: 2);
    _text(
      canvas,
      'NOVEMBER',
      const Offset(341, 125),
      15,
      const Color(0xfffff5e5),
      weight: FontWeight.w700,
      letterSpacing: 1.4,
    );
    for (final x in [294.0, 389.0]) {
      _rounded(
        canvas,
        Rect.fromCenter(center: Offset(x, 107), width: 6, height: 16),
        3,
        const Color(0xff4c4941),
      );
      _rounded(
        canvas,
        Rect.fromCenter(center: Offset(x - 1, 105), width: 1, height: 9),
        1,
        const Color(0xffa5a195),
      );
    }
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (var i = 0; i < weekdays.length; i++) {
      _text(
        canvas,
        weekdays[i],
        Offset(284.0 + i * 19, 157),
        8,
        const Color(0xff625c51),
        weight: FontWeight.w700,
      );
    }
    for (var i = 0; i < 7; i++) {
      final y = 167.0 + i * 16;
      canvas.drawLine(
        Offset(276, y),
        Offset(406, y),
        Paint()
          ..color = const Color(0xffdcd5c6)
          ..strokeWidth = .65,
      );
    }
    for (var i = 0; i < 30; i++) {
      _text(
        canvas,
        '${i + 1}',
        Offset(284.0 + i % 7 * 19, 175.0 + (i ~/ 7) * 16),
        9,
        const Color(0xff4f4b43),
      );
    }
  }

  void _drawPinboard(Canvas canvas) {
    const board = Rect.fromLTWH(755, 178, 174, 113);
    _paperShadow(canvas, board, 3);
    _wash(canvas, board, const [
      Color(0xff947156),
      Color(0xff634d3d),
    ], radius: 3);
    final cork = board.deflate(7);
    _wash(canvas, cork, const [Color(0xffad8b66), Color(0xff937452)]);
    final flecks = math.Random(18);
    for (var i = 0; i < 850; i++) {
      canvas.drawCircle(
        Offset(
          cork.left + flecks.nextDouble() * cork.width,
          cork.top + flecks.nextDouble() * cork.height,
        ),
        .25 + flecks.nextDouble() * .7,
        Paint()
          ..color =
              (i.isEven ? const Color(0xff513627) : const Color(0xfff1ce9a))
                  .withValues(alpha: .26),
      );
    }
    _note(
      canvas,
      const Offset(800, 230),
      const Size(44, 58),
      -.15,
      const Color(0xffeee2bf),
    );
    _note(
      canvas,
      const Offset(849, 237),
      const Size(47, 55),
      .10,
      const Color(0xffe9e7d9),
    );
    _note(
      canvas,
      const Offset(891, 220),
      const Size(36, 38),
      -.10,
      const Color(0xffc0c8b1),
    );
  }

  void _note(
    Canvas canvas,
    Offset center,
    Size size,
    double angle,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.width,
      height: size.height,
    );
    _paperShadow(canvas, rect, 1);
    _rounded(canvas, rect, 1, color);
    final pin = Offset(0, rect.top + 5);
    canvas.drawCircle(
      pin.translate(.7, 1),
      3.2,
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawCircle(pin, 2.7, Paint()..color = const Color(0xff8d5546));
    canvas.drawCircle(
      pin.translate(-.6, -.6),
      .9,
      Paint()..color = const Color(0xffc28a75),
    );
    canvas.restore();
  }

  void _drawComputer(Canvas canvas) {
    const caseLight = Color(0xffede5ce);
    const caseMid = Color(0xffc7bea6);
    const caseDark = Color(0xff8f8570);
    _shadow(canvas, const Rect.fromLTWH(395, 386, 338, 35), blur: 10);
    // Tower side and drive bays.
    _polygon(canvas, const [
      Offset(699, 222),
      Offset(727, 232),
      Offset(727, 390),
      Offset(699, 401),
    ], const Color(0xffa69d87));
    _wash(canvas, const Rect.fromLTWH(636, 221, 69, 181), const [
      caseLight,
      caseMid,
    ], radius: 5);
    for (final y in [235.0, 258.0, 281.0]) {
      _rounded(canvas, Rect.fromLTWH(643, y, 55, 18), 2, caseDark);
      _wash(canvas, Rect.fromLTWH(644, y + 1, 53, 15), const [
        Color(0xffe1dbc9),
        Color(0xffb9b19e),
      ], radius: 2);
      _rounded(
        canvas,
        Rect.fromLTWH(648, y + 4, 42, 2),
        1,
        const Color(0xff807b6c),
      );
      _rounded(
        canvas,
        Rect.fromLTWH(688, y + 10, 5, 2.5),
        1,
        const Color(0xff8b826f),
      );
    }
    for (var i = 0; i < 5; i++) {
      _rounded(
        canvas,
        Rect.fromLTWH(652, 317.0 + i * 4, 37, 1.7),
        1,
        const Color(0xffa99d85),
      );
    }
    _rounded(canvas, const Rect.fromLTWH(665, 355, 13, 24), 6, caseDark);
    _wash(canvas, const Rect.fromLTWH(667, 357, 9, 19), const [
      caseLight,
      caseMid,
    ], radius: 5);
    canvas.drawCircle(
      const Offset(672, 347),
      2,
      Paint()..color = const Color(0xff758c5f),
    );

    // The thick CRT enclosure, curved glass, and swivel stand.
    _wash(canvas, const Rect.fromLTWH(474, 366, 94, 30), const [
      caseDark,
      caseMid,
    ], radius: 8);
    _wash(canvas, const Rect.fromLTWH(446, 386, 148, 15), const [
      caseLight,
      caseMid,
    ], radius: 7);
    _polygon(canvas, const [
      Offset(433, 237),
      Offset(453, 223),
      Offset(609, 223),
      Offset(629, 237),
    ], const Color(0xffc6bea9));
    _wash(canvas, const Rect.fromLTWH(422, 235, 207, 145), const [
      caseLight,
      caseMid,
    ], radius: 12);
    _rounded(canvas, const Rect.fromLTWH(434, 245, 183, 116), 12, caseDark);
    _rounded(
      canvas,
      const Rect.fromLTWH(438, 249, 175, 108),
      11,
      const Color(0xff252825),
    );
    final glass = RRect.fromRectAndRadius(
      const Rect.fromLTWH(443, 253, 165, 100),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.48, -.6),
          radius: 1.2,
          colors: [Color(0xff4c5551), Color(0xff343c39), Color(0xff232825)],
        ).createShader(glass.outerRect),
    );
    canvas.drawRRect(
      glass.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff65706a).withValues(alpha: .48),
    );
    _rounded(canvas, const Rect.fromLTWH(590, 365, 18, 7), 2, caseDark);
    canvas.drawCircle(
      const Offset(584, 368.5),
      2,
      Paint()..color = const Color(0xff829a6b),
    );

    final cable = Path()
      ..moveTo(569, 393)
      ..cubicTo(604, 374, 637, 389, 657, 408)
      ..cubicTo(670, 418, 689, 405, 700, 410);
    canvas.drawPath(
      cable,
      Paint()
        ..color = const Color(0xff6c6353)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _polygon(canvas, const [
      Offset(428, 399),
      Offset(621, 399),
      Offset(644, 431),
      Offset(408, 431),
    ], caseLight);
    _rounded(canvas, const Rect.fromLTWH(408, 430, 236, 5), 2, caseDark);
    for (var row = 0; row < 4; row++) {
      final y = 403.5 + row * 6.3;
      final start = 431.0 - row * 3.7;
      for (var col = 0; col < 17; col++) {
        if (row == 3 && col >= 4 && col <= 10) continue;
        final x = start + col * (10.5 + .37 * row) + (col >= 13 ? 5 : 0);
        _rounded(canvas, Rect.fromLTWH(x, y, 8.3, 4.8), 1, caseDark);
        _rounded(
          canvas,
          Rect.fromLTWH(x, y, 7.8, 3.5),
          1,
          const Color(0xfff2ead6),
        );
      }
      if (row == 3) {
        _rounded(canvas, Rect.fromLTWH(start + 48, y, 82, 4.8), 1, caseDark);
        _rounded(
          canvas,
          Rect.fromLTWH(start + 48, y, 82, 3.5),
          1,
          const Color(0xfff2ead6),
        );
      }
    }
    _wash(canvas, const Rect.fromLTWH(688, 407, 27, 25), const [
      caseLight,
      caseMid,
    ], radius: 10);
    _rounded(canvas, const Rect.fromLTWH(701, 408, 1, 10), .5, caseDark);
  }

  @override
  bool shouldRepaint(DiscoverOfficePainter oldDelegate) => false;
}

void _text(
  Canvas canvas,
  String text,
  Offset center,
  double size,
  Color color, {
  FontWeight weight = FontWeight.w500,
  double letterSpacing = 0,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  painter.dispose();
}

void _wash(Canvas canvas, Rect rect, List<Color> colors, {double radius = 0}) {
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ).createShader(rect);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    paint,
  );
}

void _rounded(Canvas canvas, Rect rect, double radius, Color color) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    Paint()..color = color,
  );
}

void _polygon(Canvas canvas, List<Offset> points, Color color) {
  canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
}

void _shadow(Canvas canvas, Rect rect, {required double blur}) {
  canvas.drawOval(
    rect,
    Paint()
      ..color = const Color(0x5031261e)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
  );
}

void _paperShadow(Canvas canvas, Rect rect, double radius) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      rect.shift(const Offset(3, 5)),
      Radius.circular(radius),
    ),
    Paint()
      ..color = const Color(0x44372e24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
}
