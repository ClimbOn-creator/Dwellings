import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_tunnel.dart';
import '../services/learning_service.dart';

import 'learning_discover_arcade.dart';
import 'learning_discover_calendar.dart';
import 'learning_discover_portal.dart';
import 'learning_discover_pinboard.dart';

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

const _crtGlass = Rect.fromLTWH(468, 241, 122, 103);
const _wallCalendar = Rect.fromLTWH(267, 132, 145, 153);
const _lampHit = Rect.fromLTWH(220, 286, 106, 115);
const _deskGlobe = Rect.fromLTWH(794, 319, 82, 94);
const _wallBoard = Rect.fromLTWH(730, 139, 250, 156);

enum _OfficePortal { buyer, calendar, globe, pinboard }

class DiscoverOffice extends StatefulWidget {
  const DiscoverOffice({
    required this.drawer,
    required this.interactive,
    required this.lampOn,
    required this.toggleLamp,
    required this.locate,
    this.buyerDashboard,
    this.loadEvents,
    this.openEvent,
    super.key,
  });

  final double drawer;
  final bool interactive, lampOn;
  final VoidCallback toggleLamp;
  final DiscoverLocate locate;
  final WidgetBuilder? buyerDashboard;
  final Future<List<LearningSeminar>> Function()? loadEvents;
  final ValueChanged<LearningSeminar>? openEvent;

  @override
  State<DiscoverOffice> createState() => _DiscoverOfficeState();
}

class _DiscoverOfficeState extends State<DiscoverOffice> {
  final _today = DiscoverToday();
  bool _opening = false;

  @override
  void dispose() {
    _today.dispose();
    super.dispose();
  }

  Future<void> _openPortal(Rect local, _OfficePortal portal) async {
    final arcade = portal == _OfficePortal.buyer;
    if (_opening) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final office = context.findRenderObject()! as RenderBox;
    final source = local.shift(
      office.localToGlobal(Offset.zero, ancestor: overlay),
    );
    final previous = AppTunnelController.current.value;
    final route = DiscoverPortalRoute(
      destination: switch (portal) {
        _OfficePortal.buyer => widget.buyerDashboard!,
        _OfficePortal.pinboard => (_) => const DiscoverPinboardPage(),
        _ => (_) => DiscoverCalendarPage(
          today: _today,
          loadEvents: widget.loadEvents!,
          openEvent: widget.openEvent!,
          locate: widget.locate,
          atlasOnly: portal == _OfficePortal.globe,
        ),
      },
      source: source,
      arcade: arcade,
      calendarPage: switch (portal) {
        _OfficePortal.buyer => null,
        _OfficePortal.calendar => _paper(_today.value, 1),
        _OfficePortal.globe => const ColoredBox(color: Color(0xff536d65)),
        _OfficePortal.pinboard => const FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(width: 480, child: DiscoverPinboard()),
        ),
      },
    );
    _opening = true;
    if (arcade) AppTunnelController.select(AppTunnel.buyer);
    try {
      await navigator.push(route);
      await route.completed;
    } finally {
      if (arcade && AppTunnelController.current.value == AppTunnel.buyer) {
        AppTunnelController.select(previous);
      }
      _opening = false;
    }
  }

  Widget _hotspot(Rect rect, String label, VoidCallback open) =>
      Positioned.fromRect(
        rect: rect,
        child: Tooltip(
          message: label,
          child: Semantics(
            label: label,
            button: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: open,
                borderRadius: BorderRadius.circular(4),
                hoverColor: Colors.white.withValues(alpha: .08),
                focusColor: const Color(0x33536ca0),
              ),
            ),
          ),
        ),
      );

  Widget _paper(DateTime today, double ink) => ExcludeSemantics(
    child: FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 410,
        child: DiscoverPaperCalendar(month: today, today: today, ink: ink),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final screen = _placeInOffice(bounds.biggest, _crtGlass);
      final calendar = _placeInOffice(bounds.biggest, _wallCalendar);
      final globe = _placeInOffice(bounds.biggest, _deskGlobe);
      final pinboard = _placeInOffice(bounds.biggest, _wallBoard);
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DiscoverOfficePainter(widget.drawer, widget.lampOn),
            ),
          ),
          Positioned.fromRect(rect: screen, child: const DiscoverArcade()),
          Positioned.fromRect(
            rect: calendar,
            child: ValueListenableBuilder<DateTime>(
              valueListenable: _today,
              builder: (context, today, _) => TweenAnimationBuilder<double>(
                key: ValueKey(today),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 630),
                builder: (context, ink, _) => _paper(today, ink),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: pinboard,
            child: const FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(width: 480, child: DiscoverPinboard()),
            ),
          ),
          if (widget.interactive)
            _hotspot(
              pinboard,
              'Zoom into pinboard',
              () => _openPortal(pinboard, _OfficePortal.pinboard),
            ),
          if (widget.interactive && widget.buyerDashboard != null)
            _hotspot(
              screen,
              'Enter Buyer Dashboard',
              () => _openPortal(screen, _OfficePortal.buyer),
            ),
          if (widget.interactive &&
              widget.loadEvents != null &&
              widget.openEvent != null)
            _hotspot(
              calendar,
              'Open Discover calendar',
              () => _openPortal(calendar, _OfficePortal.calendar),
            ),
          if (widget.interactive &&
              widget.loadEvents != null &&
              widget.openEvent != null)
            _hotspot(
              globe,
              'Open desk globe',
              () => _openPortal(globe, _OfficePortal.globe),
            ),
          if (widget.interactive)
            _hotspot(
              _placeInOffice(bounds.biggest, _lampHit),
              widget.lampOn ? 'Turn lamp off' : 'Turn lamp on',
              widget.toggleLamp,
            ),
        ],
      );
    },
  );
}

class _DiscoverOfficePainter extends CustomPainter {
  const _DiscoverOfficePainter(this.drawer, this.lampOn);

  final double drawer;
  final bool lampOn;

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
    _deskAccessories(canvas);
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
    final surface = Path()
      ..addPolygon(const [
        Offset(235, 368),
        Offset(870, 368),
        Offset(960, 415),
        Offset(152, 415),
      ], true);
    c.drawPath(surface, Paint()..color = const Color(0xff414242));
    if (lampOn) {
      c.save();
      c.clipPath(surface);
      c.translate(340, 391);
      c.scale(1, .32);
      final pool = Rect.fromCircle(center: Offset.zero, radius: 104);
      c.drawOval(
        pool,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xaaedc586), Color(0x59d6a362), Color(0x00d6a362)],
            stops: [0, .52, 1],
          ).createShader(pool),
      );
      c.restore();
    }
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

  void _deskAccessories(Canvas c) {
    _poly(c, const [
      Offset(301, 388),
      Offset(357, 382),
      Offset(380, 399),
      Offset(311, 409),
    ], const Color(0xffc1b79e));
    _poly(c, const [
      Offset(309, 381),
      Offset(368, 387),
      Offset(371, 405),
      Offset(298, 399),
    ], const Color(0xfff4ebd4));
    _poly(c, const [
      Offset(354, 403),
      Offset(359, 397),
      Offset(371, 405),
    ], const Color(0xffbeb094));
    _line(
      c,
      const Offset(301, 400),
      const Offset(350, 404),
      const Color(0xff806e55),
      1.5,
    );
    _line(
      c,
      const Offset(311, 408),
      const Offset(379, 399),
      const Color(0xff86785d),
      1.4,
    );
    _line(
      c,
      const Offset(313, 387),
      const Offset(347, 391),
      const Color(0xff998b72),
      1.2,
    );
    _line(
      c,
      const Offset(310, 391),
      const Offset(354, 395),
      const Color(0xff998b72),
      1.2,
    );
    _line(
      c,
      const Offset(308, 395),
      const Offset(332, 398),
      const Color(0xff998b72),
      1.2,
    );
    for (final center in const [
      Offset(396, 400),
      Offset(414, 379),
      Offset(387, 378),
      Offset(290, 383),
    ]) {
      final x = center.dx;
      final y = center.dy;
      _poly(c, [
        Offset(x - 10, y),
        Offset(x - 5, y - 7),
        Offset(x + 2, y - 8),
        Offset(x + 9, y - 4),
        Offset(x + 11, y + 3),
        Offset(x + 3, y + 8),
        Offset(x - 6, y + 6),
      ], const Color(0xffd4ccb6));
      _line(
        c,
        Offset(x - 4, y - 4),
        Offset(x + 4, y + 3),
        const Color(0xff958d79),
        1.3,
      );
      _line(
        c,
        Offset(x - 6, y + 3),
        Offset(x + 3, y - 2),
        const Color(0xffa79a84),
        1,
      );
    }
    _line(
      c,
      const Offset(834, 379),
      const Offset(839, 402),
      const Color(0xffb19878),
      5,
    );
    _poly(c, const [
      Offset(821, 401),
      Offset(851, 401),
      Offset(859, 409),
      Offset(814, 409),
    ], const Color(0xff806b55));
    c.drawArc(
      const Rect.fromLTWH(801, 322, 67, 73),
      -.65,
      3.3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xffb5a186),
    );
    const centre = Offset(834, 356);
    c.drawCircle(centre, 29, Paint()..color = const Color(0xff7f9e9c));
    final grid = Paint()
      ..color = const Color(0xff537576)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    c.drawOval(const Rect.fromLTWH(824, 328, 20, 56), grid);
    c.drawOval(const Rect.fromLTWH(806, 349, 56, 14), grid);
    _poly(c, const [
      Offset(813, 344),
      Offset(826, 334),
      Offset(838, 334),
      Offset(835, 344),
      Offset(826, 349),
      Offset(826, 356),
      Offset(820, 360),
      Offset(817, 351),
    ], const Color(0xffc2bd84));
    _poly(c, const [
      Offset(832, 360),
      Offset(842, 358),
      Offset(847, 364),
      Offset(842, 372),
      Offset(838, 377),
      Offset(836, 368),
    ], const Color(0xffc2bd84));
    _poly(c, const [
      Offset(848, 338),
      Offset(855, 341),
      Offset(860, 349),
      Offset(852, 353),
      Offset(846, 348),
    ], const Color(0xffb9b17b));

    // A chipped pen cup and the pens behind its rim.
    _line(
      c,
      const Offset(445, 374),
      const Offset(435, 340),
      const Color(0xff9b5347),
      4,
    );
    _line(
      c,
      const Offset(451, 373),
      const Offset(450, 335),
      const Color(0xff566f75),
      4,
    );
    _line(
      c,
      const Offset(455, 375),
      const Offset(464, 342),
      const Color(0xffbda77d),
      4,
    );
    _line(
      c,
      const Offset(458, 373),
      const Offset(470, 348),
      const Color(0xff69794e),
      3,
    );
    _poly(c, const [
      Offset(435, 361),
      Offset(466, 361),
      Offset(462, 392),
      Offset(441, 392),
    ], const Color(0xffa28465));
    _line(
      c,
      const Offset(436, 362),
      const Offset(465, 362),
      const Color(0xffc0a483),
      2,
    );
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

  void _computer(Canvas c) {
    const beige = Color(0xffd8c9a9);
    const light = Color(0xffebdfc4);
    const shade = Color(0xffb2a184);
    _fill(c, const Rect.fromLTWH(609, 219, 59, 169), shade);
    _fill(c, const Rect.fromLTWH(612, 221, 53, 163), beige);
    for (final y in [231.0, 251.0, 271.0]) {
      _fill(c, Rect.fromLTWH(618, y, 41, 14), shade);
      _fill(c, Rect.fromLTWH(620, y + 2, 37, 9), light);
      _fill(c, Rect.fromLTWH(624, y + 4, 26, 2), const Color(0xff8d806b));
    }
    for (var i = 0; i < 5; i++) {
      _fill(c, Rect.fromLTWH(623, 298.0 + i * 6, 31, 2), shade);
    }
    _fill(c, const Rect.fromLTWH(635, 350, 8, 17), shade);
    c.drawCircle(
      const Offset(639, 342),
      2,
      Paint()..color = const Color(0xff74875d),
    );
    _fill(c, const Rect.fromLTWH(500, 351, 58, 26), shade);
    _fill(c, const Rect.fromLTWH(483, 371, 93, 12), beige);
    _poly(c, const [
      Offset(460, 220),
      Offset(598, 220),
      Offset(607, 229),
      Offset(607, 350),
      Offset(598, 359),
      Offset(460, 359),
      Offset(451, 350),
      Offset(451, 229),
    ], beige);
    _line(c, const Offset(461, 224), const Offset(597, 224), light, 2);
    _poly(c, const [
      Offset(469, 233),
      Offset(589, 233),
      Offset(597, 241),
      Offset(597, 344),
      Offset(589, 351),
      Offset(469, 351),
      Offset(461, 344),
      Offset(461, 241),
    ], const Color(0xff8f8169));
    _line(c, const Offset(468, 350), const Offset(477, 353), shade, 2);
    c.drawCircle(
      const Offset(558, 355),
      2,
      Paint()..color = const Color(0xff7b9b5f),
    );
    _fill(c, const Rect.fromLTWH(565, 353, 12, 4), shade);

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
    c.save();
    c.translate(247, 398);
    c.scale(1.23);
    c.translate(-247, -398);
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
    ], lampOn ? const Color(0xfff0d8a9) : const Color(0xff675446));
    _line(
      c,
      const Offset(278, 314),
      const Offset(284, 309),
      const Color(0xffb49374),
      2,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_DiscoverOfficePainter oldDelegate) =>
      oldDelegate.drawer != drawer || oldDelegate.lampOn != lampOn;
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
