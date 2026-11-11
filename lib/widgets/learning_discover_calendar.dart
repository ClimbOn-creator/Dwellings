import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../services/learning_service.dart';
import '../services/device_location_service.dart';
import 'canada_event_map.dart';
import 'learning_area_picker.dart';

class DiscoverToday extends ValueNotifier<DateTime>
    with WidgetsBindingObserver {
  DiscoverToday() : super(DateUtils.dateOnly(DateTime.now())) {
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  Timer? _midnight;

  void _schedule() {
    _midnight?.cancel();
    final now = DateTime.now();
    value = DateUtils.dateOnly(now);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(tomorrow.difference(now), _schedule);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

const calendarPaper = Color(0xfff5f5ed);
const calendarInk = Color(0xff273d3b);
const calendarPen = Color(0xffb63236);
const _vancouver = SeminarMapRegion(49.2827, -123.1207, radiusKm: 700);

int calendarOffset(DateTime month) =>
    DateTime(month.year, month.month).weekday % 7;

void paintCalendarMark(
  Canvas canvas,
  Rect bounds, {
  required bool today,
  required double progress,
}) {
  final paint = Paint()
    ..color = calendarPen
    ..strokeWidth = math.max(.7, bounds.height * .075)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final path = Path();
  if (today) {
    final x = bounds.center.dx;
    final y = bounds.center.dy;
    final rx = bounds.width * .39;
    final ry = bounds.height * .39;
    path
      ..moveTo(x + rx * .74, y - ry * .69)
      ..cubicTo(
        x - rx * .16,
        y - ry * 1.42,
        x - rx * 1.35,
        y - ry * .51,
        x - rx,
        y + ry * .44,
      )
      ..cubicTo(
        x - rx * .59,
        y + ry * 1.31,
        x + rx * 1.27,
        y + ry,
        x + rx,
        y - ry * .06,
      )
      ..quadraticBezierTo(x + rx * .85, y - ry * .8, x + rx * .35, y - ry);
  } else {
    path
      ..moveTo(
        bounds.left + bounds.width * .24,
        bounds.bottom - bounds.height * .22,
      )
      ..lineTo(
        bounds.right - bounds.width * .2,
        bounds.top + bounds.height * .22,
      )
      ..moveTo(
        bounds.left + bounds.width * .29,
        bounds.top + bounds.height * .21,
      )
      ..lineTo(
        bounds.right - bounds.width * .25,
        bounds.bottom - bounds.height * .18,
      );
  }
  final segments = path.computeMetrics().toList();
  final total = segments.fold(
    0.0,
    (length, segment) => length + segment.length,
  );
  var remaining = total * progress;
  for (final segment in segments) {
    if (remaining <= 0) break;
    canvas.drawPath(
      segment.extractPath(0, math.min(segment.length, remaining)),
      paint,
    );
    remaining -= segment.length;
  }
}

typedef DiscoverLocate =
    Future<({double latitude, double longitude})> Function();

class DiscoverCalendarPage extends StatefulWidget {
  const DiscoverCalendarPage({
    super.key,
    required this.today,
    required this.loadEvents,
    required this.openEvent,
    this.locate = DeviceLocationService.locate,
    this.atlasOnly = false,
  });

  final ValueListenable<DateTime> today;
  final Future<List<LearningSeminar>> Function() loadEvents;
  final ValueChanged<LearningSeminar> openEvent;
  final DiscoverLocate locate;
  final bool atlasOnly;

  @override
  State<DiscoverCalendarPage> createState() => _DiscoverCalendarPageState();
}

class _DiscoverCalendarPageState extends State<DiscoverCalendarPage> {
  DateTime? _browsedMonth;
  late Future<List<LearningSeminar>> _events = widget.loadEvents();
  SeminarMapRegion _region = _vancouver;
  bool _locating = false;
  String? _locationMessage;

  DateTime get _month {
    final today = widget.today.value;
    return _browsedMonth ?? DateTime(today.year, today.month);
  }

  void _setRegion(SeminarMapRegion region, String message) {
    setState(() {
      _region = region;
      _locationMessage = message;
    });
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final position = await widget.locate().timeout(
        const Duration(seconds: 15),
      );
      final region = SeminarMapRegion(
        position.latitude,
        position.longitude,
        radiusKm: 700,
      );
      final geometry = await CanadaMapGeometry.asset;
      if (!mounted) return;
      if (!region
          .projectedBounds(geometry.normalized)
          .overlaps(const Rect.fromLTWH(0, 0, 1, 1))) {
        setState(
          () => _locationMessage =
              'Choose a Canadian city to find nearby events on this map.',
        );
        return;
      }
      _setRegion(region, 'Map centered on your location.');
    } catch (error) {
      if (mounted) {
        final denied =
            error is StateError &&
            error.message.toLowerCase().contains('permission');
        setState(
          () => _locationMessage = denied
              ? 'Browser location is blocked. Allow it in your site settings or choose a city.'
              : 'Location is unavailable. Try again or choose a city.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseCity() async {
    final city = await chooseLearningArea(
      context,
      description: 'Center the event map on a Canadian city.',
      allowDeviceLocation: false,
    );
    if (!mounted || city == null) return;
    _setRegion(
      SeminarMapRegion(city.latitude, city.longitude, radiusKm: 700),
      'Map centered on ${city.name}.',
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<DateTime>(
    valueListenable: widget.today,
    builder: (context, today, _) => Scaffold(
      backgroundColor: calendarPaper,
      appBar: AppBar(
        backgroundColor: calendarPaper,
        leading: const BackButton(),
        title: Text(widget.atlasOnly ? 'Discover atlas' : 'Discover calendar'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) => FutureBuilder<List<LearningSeminar>>(
            future: _events,
            builder: (context, snapshot) {
              if (widget.atlasOnly) return _atlas(snapshot);
              final calendar = _calendar(today, snapshot);
              if (bounds.maxWidth < 820) {
                return ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    calendar,
                    const SizedBox(height: 16),
                    SizedBox(height: 540, child: _atlas(snapshot)),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      child: calendar,
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xffc5bbab)),
                  Expanded(child: _atlas(snapshot)),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _calendar(
    DateTime today,
    AsyncSnapshot<List<LearningSeminar>> snapshot,
  ) {
    final events = (snapshot.data ?? []).where((event) {
      final date = event.startsAt.toLocal();
      return date.year == _month.year &&
          date.month == _month.month &&
          event.status != 'cancelled';
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    bool inPerson(LearningSeminar event) =>
        event.mode == 'in_person' || event.mode == 'hybrid';
    final meetingsByDay = <int, List<LearningSeminar>>{};
    for (final event in events.where(inPerson)) {
      meetingsByDay
          .putIfAbsent(event.startsAt.toLocal().day, () => [])
          .add(event);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => setState(
                () => _browsedMonth = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => setState(
                () => _browsedMonth = DateTime(_month.year, _month.month + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        TweenAnimationBuilder<double>(
          key: ValueKey(today),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 630),
          builder: (context, ink, _) => DiscoverPaperCalendar(
            month: _month,
            today: today,
            ink: ink,
            meetings: meetingsByDay,
            openMeeting: widget.openEvent,
          ),
        ),
        const SizedBox(height: 22),
        if (snapshot.hasData) ...[
          Text(
            'In-person meetings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (meetingsByDay.isEmpty)
            const Text('No meetings scheduled this month.'),
          for (final day in meetingsByDay.values)
            for (final event in day.skip(10))
              ListTile(
                title: Text(event.title),
                onTap: () => widget.openEvent(event),
              ),
          const SizedBox(height: 16),
          _eventList(
            'Resource meetings',
            events.where(
              (event) => event.kind == 'meeting' && !inPerson(event),
            ),
          ),
        ],
      ],
    );
  }

  Widget _atlas(AsyncSnapshot<List<LearningSeminar>> snapshot) {
    final region = _region;
    final now = DateTime.now();
    final events = [
      for (final event in snapshot.data ?? <LearningSeminar>[])
        if (event.visibleOnMap(now)) event,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event map', style: Theme.of(context).textTheme.titleLarge),
              Text(
                _locationMessage ??
                    (region == _vancouver
                        ? 'Map centered on Vancouver.'
                        : 'Explore published events on the map.'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _locating ? null : _locate,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _locating ? 'Finding location…' : 'Use my location',
                    ),
                  ),
                  TextButton(
                    onPressed: _locating ? null : _chooseCity,
                    child: const Text('Choose a city'),
                  ),
                  if (region != _vancouver)
                    TextButton(
                      onPressed: _locating
                          ? null
                          : () => _setRegion(
                              _vancouver,
                              'Map centered on Vancouver.',
                            ),
                      child: const Text('Back to Vancouver'),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: CanadaEventMap(
            events: events,
            region: region,
            onOpen: widget.openEvent,
            expandToFill: true,
            showRegionOutline: false,
          ),
        ),
        if (snapshot.hasError)
          TextButton.icon(
            onPressed: () => setState(() => _events = widget.loadEvents()),
            icon: const Icon(Icons.refresh),
            label: const Text('Could not load events. Retry'),
          )
        else if (snapshot.connectionState == ConnectionState.done)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              events.isEmpty
                  ? 'No upcoming mapped events.'
                  : '${events.length} mapped ${events.length == 1 ? 'event' : 'events'}',
            ),
          ),
      ],
    );
  }

  Widget _eventList(String title, Iterable<LearningSeminar> events) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (events.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 9),
          child: Text('No meetings scheduled this month.'),
        ),
      for (final event in events)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(event.title),
          subtitle: Text(
            [
              DateFormat(
                'EEE, MMM d · h:mm a',
              ).format(event.startsAt.toLocal()),
              if (event.venue.isNotEmpty) event.venue,
              if (event.areaName.isNotEmpty) event.areaName,
            ].join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.openEvent(event),
        ),
    ],
  );
}

class DiscoverPaperCalendar extends StatelessWidget {
  const DiscoverPaperCalendar({
    required this.month,
    required this.today,
    required this.ink,
    this.meetings,
    this.openMeeting,
    super.key,
  });

  final DateTime month, today;
  final double ink;
  final Map<int, List<LearningSeminar>>? meetings;
  final ValueChanged<LearningSeminar>? openMeeting;

  double get _dayHeight => meetings == null ? 42 : 222;

  @override
  Widget build(BuildContext context) {
    final offset = calendarOffset(month);
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xfff1e7d3),
        border: Border.fromBorderSide(BorderSide(color: Color(0xffb4a184))),
        boxShadow: [BoxShadow(color: Color(0x320c2724), offset: Offset(5, 5))],
      ),
      position: DecorationPosition.background,
      child: CustomPaint(
        foregroundPainter: const _PaperCreases(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomPaint(
              foregroundPainter: const _CalendarWear(),
              child: ColoredBox(
                color: const Color(0xff655546),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    DateFormat.yMMMM().format(month).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: calendarPaper,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
              child: Table(
                children: [
                  TableRow(
                    children: [
                      for (final day in const [
                        'Sun',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                      ])
                        Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: calendarInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var row = 0; row < 6; row++)
                    TableRow(
                      children: [
                        for (var col = 0; col < 7; col++)
                          _day(row * 7 + col - offset + 1, count),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _day(int day, int count) {
    if (day < 1 || day > count) return SizedBox(height: _dayHeight);
    final date = DateTime(month.year, month.month, day);
    final current = date == today;
    final past = date.isBefore(today);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final dateLabel = Semantics(
      label:
          '${DateFormat.yMMMMd().format(date)}${current
              ? ', today'
              : past
              ? ', passed'
              : ''}',
      excludeSemantics: true,
      child: CustomPaint(
        foregroundPainter: current || past
            ? _DayMark(current, current || date == yesterday ? ink : 1)
            : null,
        child: SizedBox(
          height: 27,
          width: 31,
          child: Center(child: Text('$day')),
        ),
      ),
    );
    return Container(
      height: _dayHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: Color(0xffcbbd9f)),
          right: meetings != null
              ? const BorderSide(color: Color(0xffcbbd9f))
              : BorderSide.none,
        ),
      ),
      child: meetings == null
          ? Center(child: dateLabel)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: dateLabel),
                for (final event
                    in (meetings?[day] ?? <LearningSeminar>[]).take(10))
                  SizedBox(
                    height: 18,
                    child: Tooltip(
                      message: event.title,
                      child: InkWell(
                        onTap: () => openMeeting?.call(event),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff513e2c),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PaperCreases extends CustomPainter {
  const _PaperCreases();

  @override
  void paint(Canvas canvas, Size size) {
    final fold = Path()
      ..addPolygon([
        Offset(size.width - 21, size.height),
        Offset(size.width - 21, size.height - 21),
        Offset(size.width, size.height - 21),
      ], true);
    canvas.drawPath(fold, Paint()..color = const Color(0xffd1bd94));
    final crease = Paint()
      ..color = const Color(0x449f8259)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .74, 53),
      Offset(size.width * .72, size.height * .90),
      crease,
    );
    canvas.drawLine(
      Offset(2, size.height * .81),
      Offset(size.width * .22, size.height * .84),
      crease,
    );
    final stain = Rect.fromCenter(
      center: Offset(size.width * .13, size.height * .88),
      width: 43,
      height: 24,
    );
    canvas.drawOval(
      stain,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0x3892754e),
    );
  }

  @override
  bool shouldRepaint(_PaperCreases oldDelegate) => false;
}

class _CalendarWear extends CustomPainter {
  const _CalendarWear();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xffb5a17f);
    canvas.drawPath(
      Path()..addPolygon([
        const Offset(4, 6),
        const Offset(42, 1),
        const Offset(44, 10),
        const Offset(31, 9),
        const Offset(8, 15),
      ], true),
      paint,
    );
    paint.color = const Color(0xff8e765e);
    canvas.drawPath(
      Path()..addPolygon([
        Offset(size.width - 39, 0),
        Offset(size.width, 0),
        Offset(size.width, 12),
        Offset(size.width - 16, 8),
      ], true),
      paint,
    );
    paint.color = const Color(0xffa48c73);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 31, size.height - 8, 25, 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CalendarWear oldDelegate) => false;
}

class _DayMark extends CustomPainter {
  const _DayMark(this.today, this.progress);
  final bool today;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) => paintCalendarMark(
    canvas,
    Offset.zero & size,
    today: today,
    progress: progress,
  );

  @override
  bool shouldRepaint(_DayMark oldDelegate) =>
      oldDelegate.today != today || oldDelegate.progress != progress;
}
