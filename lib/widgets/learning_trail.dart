import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/learning_lesson_content.dart';
import '../services/site_content_service.dart';
import 'learning_activity_ui.dart';
import 'site_copy_text.dart';

const _stops = [
  (id: 'discover', destination: 'discover', icon: Icons.explore_outlined),
  (id: 'search', destination: 'search', icon: Icons.search),
  (id: 'evaluate', destination: 'evaluate', icon: Icons.fact_check_outlined),
  (id: 'financial', destination: 'financial', icon: Icons.calculate_outlined),
  (id: 'documents', destination: 'room', icon: Icons.folder_open_outlined),
  (
    id: 'dealStructure',
    destination: 'dealStructure',
    icon: Icons.handshake_outlined,
  ),
  (id: 'transition', destination: 'transition', icon: Icons.key_outlined),
  (id: 'faq', destination: 'faq', icon: Icons.chat_bubble_outline),
];

class LearningTrail extends StatefulWidget {
  const LearningTrail({
    super.key,
    required this.controller,
    required this.onOpen,
  });
  final ScrollController controller;
  final ValueChanged<String> onOpen;

  @override
  State<LearningTrail> createState() => _LearningTrailState();
}

class _LearningTrailState extends State<LearningTrail> {
  final _trailKey = GlobalKey();
  final _rows = List.generate(_stops.length, (_) => GlobalKey());
  List<Offset> _points = [];
  Offset _alex = Offset.zero;
  int _reached = 0;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_measure);
    SiteContentService.revision.addListener(_scheduleMeasure);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_measure);
    SiteContentService.revision.removeListener(_scheduleMeasure);
    super.dispose();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted || _trailKey.currentContext == null) return;
    final trail = _trailKey.currentContext!.findRenderObject()! as RenderBox;
    final viewport =
        Scrollable.of(context).context.findRenderObject()! as RenderBox;
    final narrow = trail.size.width < 760;
    final points = [
      for (var i = 0; i < _rows.length; i++)
        Offset(
          _nodeX(trail.size.width, i, narrow),
          (_rows[i].currentContext!.findRenderObject()! as RenderBox)
                  .localToGlobal(Offset.zero, ancestor: trail)
                  .dy +
              72,
        ),
    ];
    final focus =
        (viewport.size.height * .42 -
                trail.localToGlobal(Offset.zero, ancestor: viewport).dy)
            .clamp(points.first.dy, points.last.dy);
    var reached = _reached;
    for (var i = 0; i < points.length; i++) {
      if (points[i].dy <= focus + 70) reached = math.max(reached, i);
    }
    var alex = points.last;
    var phase = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      if (focus <= points[i + 1].dy) {
        final t = ((focus - points[i].dy) / (points[i + 1].dy - points[i].dy))
            .clamp(0.0, 1.0);
        final eased = t * t * (3 - 2 * t);
        alex = Offset(
          points[i].dx + (points[i + 1].dx - points[i].dx) * eased,
          focus,
        );
        phase = focus / 27;
        break;
      }
    }
    if (!listEquals(points, _points) ||
        reached != _reached ||
        (alex - _alex).distance > .2) {
      setState(() {
        _points = points;
        _alex = alex;
        _reached = reached;
        _phase = phase;
      });
    }
  }

  double _nodeX(double width, int index, bool narrow) =>
      narrow ? 38 : width / 2 + math.sin(index * math.pi / 2) * 48;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      _scheduleMeasure();
      final narrow = bounds.maxWidth < 760;
      final reduced = MediaQuery.disableAnimationsOf(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const Icon(Icons.route, color: activityForest, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: creativeValue(
                    'roadmap.progress',
                    '${_reached + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: activityForest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: activitySage,
              child: Stack(
                key: _trailKey,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _TrailPainter(_points, _alex)),
                  ),
                  Column(
                    children: [
                      for (var i = 0; i < _stops.length; i++)
                        ConstrainedBox(
                          key: _rows[i],
                          constraints: const BoxConstraints(minHeight: 220),
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  narrow
                                      ? 84
                                      : (i.isEven ? 24 : bounds.maxWidth * .61),
                                  20,
                                  narrow
                                      ? 18
                                      : (i.isEven ? bounds.maxWidth * .61 : 24),
                                  36,
                                ),
                                child: Stack(
                                  children: [
                                    ExcludeSemantics(
                                      excluding: i > _reached,
                                      child: ExcludeFocus(
                                        excluding: i > _reached,
                                        child: AnimatedOpacity(
                                          opacity: i <= _reached ? 1 : 0,
                                          duration: reduced
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 450,
                                                ),
                                          child: _landmark(i),
                                        ),
                                      ),
                                    ),
                                    if (i > _reached)
                                      const Positioned.fill(
                                        child: IgnorePointer(
                                          child: CustomPaint(
                                            painter: _FogPainter(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: _nodeX(bounds.maxWidth, i, narrow) - 13,
                                top: 59,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i <= _reached
                                        ? activityForest
                                        : const Color(0xFFC8D1C2),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (_points.isNotEmpty)
                    Positioned(
                      left: _alex.dx - 19,
                      top: _alex.dy - 57,
                      child: IgnorePointer(
                        child: AlexAvatar(phase: reduced ? 0 : _phase),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_reached == _stops.length - 1) creativeCopy('roadmap.finish'),
        ],
      );
    },
  );

  Widget _landmark(int index) {
    final item = _stops[index];
    Widget copy(String suffix, TextStyle style) {
      final key = 'learning.lesson.syllabus.${item.id}.$suffix';
      return SiteCopyText(key, learningLessonCopy[key]!, style: style);
    }

    return Material(
      color: const Color(0xFFFDFCF6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('trail-stop-$index'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onOpen(item.destination),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: activityForest, size: 28),
              const SizedBox(height: 14),
              copy(
                'title',
                const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: activityInk,
                ),
              ),
              const SizedBox(height: 8),
              copy('body', activityBody),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: copy(
                      'time',
                      const TextStyle(fontSize: 12, color: activityForest),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: activityForest,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter(this.points, this.alex);
  final List<Offset> points;
  final Offset alex;

  @override
  void paint(Canvas c, Size size) {
    final paint = Paint();
    for (var i = 0; i < 24; i++) {
      final x = (i * 131.0 + 37) % size.width;
      final y = (i * 197.0 + 120) % size.height;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 110, height: 45),
        paint..color = const Color(0x226F8C66),
      );
      final tree = Path()
        ..moveTo(x, y - 35)
        ..lineTo(x - 12, y - 5)
        ..lineTo(x + 12, y - 5)
        ..close();
      c.drawPath(tree, paint..color = const Color(0x44788A69));
      c.drawRect(
        Rect.fromLTWH(x - 2, y - 5, 4, 10),
        paint..color = const Color(0x4483745B),
      );
    }
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final mid = (points[i - 1].dy + points[i].dy) / 2;
      path.cubicTo(
        points[i - 1].dx,
        mid,
        points[i].dx,
        mid,
        points[i].dx,
        points[i].dy,
      );
    }
    c.drawPath(
      path,
      paint
        ..color = const Color(0xFFC7B89B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      path,
      paint
        ..color = const Color(0xFFF5E9CD)
        ..strokeWidth = 14,
    );
    final metric = path.computeMetrics().first;
    final progress =
        ((alex.dy - points.first.dy) / (points.last.dy - points.first.dy))
            .clamp(0.0, 1.0);
    c.drawPath(
      metric.extractPath(0, metric.length * progress),
      paint
        ..color = const Color(0xFF809671)
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      !listEquals(oldDelegate.points, points) || oldDelegate.alex != alex;
}

class _FogPainter extends CustomPainter {
  const _FogPainter();
  @override
  void paint(Canvas c, Size size) {
    final paint = Paint()
      ..color = const Color(0xCCF6F8F0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (var i = 0; i < 5; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (.22 + i * .14),
            size.height * (.4 + (i % 2) * .16),
          ),
          width: size.width * .65,
          height: size.height * .5,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FogPainter oldDelegate) => false;
}
