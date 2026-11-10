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
const calendarPen = Color(0xff536ca0);

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
    this.lastRegion,
    this.atlasOnly = false,
  });

  final ValueListenable<DateTime> today;
  final Future<List<LearningSeminar>> Function() loadEvents;
  final ValueChanged<LearningSeminar> openEvent;
  final DiscoverLocate locate;
  final ValueNotifier<SeminarMapRegion?>? lastRegion;
  final bool atlasOnly;

  @override
  State<DiscoverCalendarPage> createState() => _DiscoverCalendarPageState();
}

class _DiscoverCalendarPageState extends State<DiscoverCalendarPage> {
  DateTime? _browsedMonth;
  late Future<List<LearningSeminar>> _events = widget.loadEvents();
  late SeminarMapRegion? _region = widget.lastRegion?.value;
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
    widget.lastRegion?.value = region;
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final position = await widget.locate();
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
      _setRegion(region, 'Showing events within 700 km of your location.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationMessage =
              'Location is unavailable. Choose a city to see nearby events.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseCity() async {
    final city = await chooseLearningArea(
      context,
      description: 'See events within 700 km of a Canadian city.',
      allowDeviceLocation: false,
    );
    if (!mounted || city == null) return;
    _setRegion(
      SeminarMapRegion(city.latitude, city.longitude, radiusKm: 700),
      'Showing events within 700 km of ${city.name}.',
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
          builder: (context, bounds) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: FutureBuilder<List<LearningSeminar>>(
                  future: _events,
                  builder: (context, snapshot) {
                    final atlas = _atlas(snapshot);
                    if (widget.atlasOnly) return atlas;
                    final calendar = _calendar(today, snapshot);
                    if (bounds.maxWidth < 820) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [calendar, const SizedBox(height: 24), atlas],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: calendar),
                        const SizedBox(width: 24),
                        Expanded(child: atlas),
                      ],
                    );
                  },
                ),
              ),
            ),
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
          builder: (context, ink, _) =>
              DiscoverPaperCalendar(month: _month, today: today, ink: ink),
        ),
        const SizedBox(height: 22),
        if (snapshot.hasData) ...[
          _eventList('In-person meetings', events.where(inPerson)),
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
    final nearby = [
      if (region != null)
        for (final event in snapshot.data ?? <LearningSeminar>[])
          if (event.visibleOnMap(now) && region.includes(event)) event,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nearby event atlas',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _locationMessage ??
              (region == null
                  ? 'Use your location or choose a city to see events within 700 km.'
                  : 'Showing events within 700 km.'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _locating ? null : _locate,
              icon: const Icon(Icons.my_location),
              label: Text(_locating ? 'Finding location…' : 'Use my location'),
            ),
            TextButton(
              onPressed: _locating ? null : _chooseCity,
              child: const Text('Choose a city'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.atlasOnly ? 480 : 380,
          child: CanadaEventMap(
            events: nearby,
            region: region,
            onOpen: widget.openEvent,
            expandToFill: true,
          ),
        ),
        if (snapshot.hasError)
          TextButton.icon(
            onPressed: () => setState(() => _events = widget.loadEvents()),
            icon: const Icon(Icons.refresh),
            label: const Text('Could not load events. Retry'),
          )
        else if (snapshot.connectionState != ConnectionState.done)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (region != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              nearby.isEmpty
                  ? 'No upcoming mapped events within 700 km.'
                  : '${nearby.length} nearby ${nearby.length == 1 ? 'event' : 'events'}',
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
    super.key,
  });

  final DateTime month, today;
  final double ink;

  @override
  Widget build(BuildContext context) {
    final offset = calendarOffset(month);
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: calendarPaper,
        boxShadow: [BoxShadow(color: Color(0x320c2724), offset: Offset(5, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: calendarInk,
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
    );
  }

  Widget _day(int day, int count) {
    if (day < 1 || day > count) return const SizedBox(height: 42);
    final date = DateTime(month.year, month.month, day);
    final current = date == today;
    final past = date.isBefore(today);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    return Semantics(
      label:
          '${DateFormat.yMMMMd().format(date)}${current
              ? ', today'
              : past
              ? ', passed'
              : ''}',
      excludeSemantics: true,
      child: Container(
        height: 42,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xffd8ddcf))),
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          foregroundPainter: current || past
              ? _DayMark(current, current || date == yesterday ? ink : 1)
              : null,
          child: SizedBox(
            height: 33,
            width: 33,
            child: Center(child: Text('$day')),
          ),
        ),
      ),
    );
  }
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
