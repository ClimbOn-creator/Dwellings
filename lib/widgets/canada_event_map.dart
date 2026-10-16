import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../services/learning_service.dart';
import '../services/learning_area_service.dart';
import 'dashboard_ui.dart';
import 'site_copy_text.dart';
import 'learning_example_cover.dart';

class CanadaMapGeometry {
  CanadaMapGeometry(this.json);
  final Map<String, dynamic> json;
  static CanadaMapGeometry? cached;
  static final Future<CanadaMapGeometry> asset = rootBundle
      .load('assets/images/canada_event_map.json')
      .then((data) {
        final value = CanadaMapGeometry(
          jsonDecode(
            utf8.decode(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            ),
          ),
        );
        cached = value;
        return value;
      });
  double get aspect => (json['aspect'] as num).toDouble();
  Offset normalized(double latitude, double longitude) {
    final p = json['projection'] as Map;
    final n = (p['n'] as num).toDouble(),
        f = (p['F'] as num).toDouble(),
        rho0 = (p['rho0'] as num).toDouble();
    final rho =
            f / math.pow(math.tan(math.pi / 4 + latitude * math.pi / 360), n),
        angle = n * (longitude + 96) * math.pi / 180;
    final x = rho * math.sin(angle), y = -(rho0 - rho * math.cos(angle));
    final b = p['bounds'] as List;
    return Offset((x - b[0]) / (b[2] - b[0]), (y - b[1]) / (b[3] - b[1]));
  }
}

class CanadaEventMap extends StatefulWidget {
  const CanadaEventMap({
    super.key,
    required this.events,
    required this.onOpen,
    this.area,
    this.nearby = false,
    this.expandToFill = false,
  });
  final List<LearningSeminar> events;
  final ValueChanged<LearningSeminar> onOpen;
  final LearningArea? area;
  final bool nearby;
  final bool expandToFill;
  @override
  State<CanadaEventMap> createState() => _CanadaEventMapState();
}

class _CanadaEventMapState extends State<CanadaEventMap> {
  final transform = TransformationController();
  Timer? closeTimer;
  String? selected;
  Size viewport = Size.zero;
  CanadaMapGeometry? geometry;
  double fitScale = 1;
  @override
  void initState() {
    super.initState();
    transform.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    closeTimer?.cancel();
    transform.removeListener(changed);
    transform.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CanadaEventMap old) {
    super.didUpdateWidget(old);
    if (old.nearby != widget.nearby || old.area?.name != widget.area?.name) {
      WidgetsBinding.instance.addPostFrameCallback((_) => fit());
    }
  }

  Size get canvasSize => Size(1000, 1000 / (geometry?.aspect ?? 1.176));
  void fit() {
    if (!mounted || geometry == null || viewport.isEmpty) return;
    fitScale = math.min(
      (viewport.width - 32) / canvasSize.width,
      (viewport.height - 32) / canvasSize.height,
    );
    final scale = widget.nearby && widget.area != null
        ? math.max(fitScale * 3, 1.2)
        : fitScale;
    final centre = widget.nearby && widget.area != null
        ? geometry!.normalized(widget.area!.latitude, widget.area!.longitude)
        : const Offset(.5, .5);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - centre.dx * canvasSize.width * scale,
        viewport.height / 2 - centre.dy * canvasSize.height * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void zoom(double factor) {
    final current = transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(fitScale * .6, 6.0);
    final ratio = next / current;
    final middle = viewport.center(Offset.zero);
    transform.value =
        (Matrix4.identity()
            ..translateByDouble(middle.dx, middle.dy, 0, 1)
            ..scaleByDouble(ratio, ratio, 1, 1)
            ..translateByDouble(-middle.dx, -middle.dy, 0, 1))
          ..multiply(transform.value);
  }

  void open(_EventGroup group) {
    closeTimer?.cancel();
    setState(() => selected = group.events.first.id);
  }

  void closeLater() {
    closeTimer?.cancel();
    closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => selected = null);
    });
  }

  List<_EventGroup> groups() {
    final result = <_EventGroup>[];
    if (geometry == null) return result;
    for (final e in widget.events.where(
      (e) => e.visibleOnMap(DateTime.now()),
    )) {
      final p = geometry!.normalized(e.latitude!, e.longitude!);
      final point = MatrixUtils.transformPoint(
        transform.value,
        Offset(p.dx * canvasSize.width, p.dy * canvasSize.height),
      );
      if (point.dx < -20 ||
          point.dx > viewport.width + 20 ||
          point.dy < -20 ||
          point.dy > viewport.height + 20)
        continue;
      final cluster = result
          .where((g) => (g.point - point).distance < 32)
          .firstOrNull;
      if (cluster == null)
        result.add(_EventGroup(point, [e]));
      else
        cluster.events.add(e);
    }
    return result;
  }

  Widget pin(_EventGroup g) => MouseRegion(
    onEnter: (_) => open(g),
    onExit: (_) => closeLater(),
    child: Focus(
      onFocusChange: (focus) {
        if (focus) open(g);
      },
      child: Material(
        color: g.events.length > 1
            ? DashboardUi.ink
            : eventColor(g.events.first.kind),
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2),
        ),
        child: InkWell(
          key: ValueKey('event-pin-${g.events.first.id}'),
          customBorder: const CircleBorder(),
          onTap: () {
            final e = g.events.first;
            // Desktop hover already opens the preview. On touch, the first tap
            // previews and the next tap follows the organizer's link.
            if (g.events.length == 1 &&
                selected == e.id &&
                e.informationUrl.isNotEmpty) {
              closeTimer?.cancel();
              setState(() => selected = null);
              widget.onOpen(e);
            } else {
              open(g);
            }
          },
          child: Semantics(
            button: true,
            label: g.events.length > 1
                ? '${g.events.length} events near ${g.events.first.areaName}'
                : g.events.first.title,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: g.events.length > 1
                    ? Text(
                        '${g.events.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Icon(
                        eventIcon(g.events.first.kind),
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget popup(_EventGroup active) => MouseRegion(
    onEnter: (_) => closeTimer?.cancel(),
    onExit: (_) => closeLater(),
    child: Material(
      key: const Key('event-map-preview'),
      elevation: 10,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 2, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    active.events.length > 1
                        ? '${active.events.length} local events'
                        : active.events.first.kindLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DashboardUi.blue,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close event preview',
                  onPressed: () => setState(() => selected = null),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: [
                for (final e in active.events)
                  EventMapPreview(
                    event: e,
                    onOpen: () {
                      setState(() => selected = null);
                      widget.onOpen(e);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<CanadaMapGeometry>(
    future: CanadaMapGeometry.asset,
    initialData: CanadaMapGeometry.cached,
    builder: (context, s) {
      if (s.hasError)
        return const SizedBox(
          height: 400,
          child: Center(
            child: SiteCopyText(
              'learning.events.mapLoadError',
              'Canada map could not load. Refresh to try again.',
            ),
          ),
        );
      if (!s.hasData)
        return const SizedBox(
          height: 480,
          child: Center(child: CircularProgressIndicator()),
        );
      geometry = s.data;
      return LayoutBuilder(
        builder: (context, box) {
          final size = Size(
            box.maxWidth,
            widget.expandToFill && box.hasBoundedHeight
                ? box.maxHeight
                : box.maxWidth < 600
                ? 460
                : 560,
          );
          if (size != viewport) {
            viewport = size;
            WidgetsBinding.instance.addPostFrameCallback((_) => fit());
          }
          final points = groups();
          final active = points
              .where((g) => g.events.any((e) => e.id == selected))
              .firstOrNull;
          final cardWidth = math.min(340.0, size.width - 24);
          final cardHeight = active == null
              ? 0.0
              : math.min(
                  active.events.length > 1 ? 340.0 : 280.0,
                  math.max(0.0, size.height - 24),
                );
          final left = active == null
              ? 12.0
              : (active.point.dx + 26 + cardWidth < size.width
                        ? active.point.dx + 26
                        : active.point.dx - cardWidth - 26)
                    .clamp(12.0, size.width - cardWidth - 12);
          final top = active == null
              ? 12.0
              : (active.point.dy - cardHeight / 2).clamp(
                  12.0,
                  size.height - cardHeight - 12,
                );
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: size.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: const Color(0xFFEAF3F5),
                      child: InteractiveViewer(
                        transformationController: transform,
                        minScale: .1,
                        maxScale: 6,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(1500),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: canvasSize,
                            painter: _CanadaPainter(geometry!),
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final g in points)
                    Positioned(
                      left: g.point.dx - 18,
                      top: g.point.dy - 18,
                      child: pin(g),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          IconButton(
                            tooltip: 'Zoom in',
                            onPressed: () => zoom(1.4),
                            icon: const Icon(Icons.add),
                          ),
                          IconButton(
                            tooltip: 'Zoom out',
                            onPressed: () => zoom(1 / 1.4),
                            icon: const Icon(Icons.remove),
                          ),
                          IconButton(
                            tooltip: 'Reset Canada map',
                            onPressed: fit,
                            icon: const Icon(Icons.center_focus_strong),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Natural Earth • Community locations',
                        style: TextStyle(
                          fontSize: 10,
                          color: DashboardUi.muted,
                        ),
                      ),
                    ),
                  ),
                  if (active != null)
                    Positioned(
                      left: left,
                      top: top,
                      width: cardWidth,
                      height: cardHeight,
                      child: popup(active),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _EventGroup {
  _EventGroup(this.point, this.events);
  final Offset point;
  final List<LearningSeminar> events;
}

Color eventColor(String kind) => switch (kind) {
  'meeting' => const Color(0xFF388F72),
  'information' => const Color(0xFFB88527),
  'workshop' => const Color(0xFF8871CA),
  _ => DashboardUi.blue,
};
IconData eventIcon(String kind) => switch (kind) {
  'meeting' => Icons.groups_outlined,
  'information' => Icons.info_outline,
  'workshop' => Icons.lightbulb_outline,
  _ => Icons.videocam_outlined,
};

class EventMapPreview extends StatelessWidget {
  const EventMapPreview({super.key, required this.event, required this.onOpen});
  final LearningSeminar event;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 76,
                height: 82,
                child: event.exampleIndex != null
                    ? LearningExampleCover(
                        index: event.exampleIndex!,
                        compact: true,
                      )
                    : event.imageUrl.isEmpty
                    ? placeholder()
                    : Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => placeholder(),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.exampleIndex == null ? '' : 'Example · '}${event.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.organization.isEmpty
                        ? 'Approved event host'
                        : event.organization,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DashboardUi.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(event.startsAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${DateFormat('h:mm a').format(event.startsAt)} ${event.startsAt.timeZoneName} · ${event.duration} min',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${event.areaName} · ${event.mode == 'in_person'
              ? 'In person'
              : event.mode == 'hybrid'
              ? 'Hybrid'
              : 'Online'}',
          style: const TextStyle(fontSize: 12, color: DashboardUi.muted),
        ),
        Row(
          children: [
            const Expanded(
              child: SiteCopyText(
                'learning.events.localTime',
                'Times shown in your local time zone',
                style: TextStyle(fontSize: 10, color: DashboardUi.muted),
              ),
            ),
            TextButton(
              onPressed: onOpen,
              child: Text(
                event.informationUrl.isEmpty ? 'View event' : 'Visit website',
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget placeholder() => ColoredBox(
    color: DashboardUi.paleBlue,
    child: Icon(eventIcon(event.kind), color: DashboardUi.blue, size: 30),
  );
}

class _CanadaPainter extends CustomPainter {
  _CanadaPainter(this.geometry);
  final CanadaMapGeometry geometry;
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFD2E4DB);
    final line = Paint()
      ..color = const Color(0xFF91B0A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9;
    for (final province in geometry.json['provinces'] as List) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final polygon in province['polygons'] as List) {
        for (final ring in polygon as List) {
          for (var i = 0; i < ring.length; i++) {
            final p = ring[i];
            if (i == 0)
              path.moveTo(p[0] * size.width, p[1] * size.height);
            else
              path.lineTo(p[0] * size.width, p[1] * size.height);
          }
          path.close();
        }
      }
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }
    const centres = {
      'BC': (54.2, -126.0),
      'AB': (55.0, -115.0),
      'SK': (54.4, -106.0),
      'MB': (55.0, -98.0),
      'ON': (51.0, -86.0),
      'QC': (53.0, -70.0),
      'NB': (46.6, -66.5),
      'NS': (45.0, -63.5),
      'PE': (46.4, -63.0),
      'NL': (53.0, -60.0),
      'YT': (64.0, -136.0),
      'NT': (65.0, -121.0),
      'NU': (69.0, -97.0),
    };
    for (final e in centres.entries) {
      final p = geometry.normalized(e.value.$1, e.value.$2);
      final t = TextPainter(
        text: TextSpan(
          text: e.key,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF668878),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(
        canvas,
        Offset(
          p.dx * size.width - t.width / 2,
          p.dy * size.height - t.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_CanadaPainter old) => old.geometry != geometry;
}
