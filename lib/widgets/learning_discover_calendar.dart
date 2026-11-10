import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../services/learning_service.dart';

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

class DiscoverCalendarPage extends StatefulWidget {
  const DiscoverCalendarPage({
    super.key,
    required this.today,
    required this.loadEvents,
    required this.openEvent,
  });

  final ValueListenable<DateTime> today;
  final Future<List<LearningSeminar>> Function() loadEvents;
  final ValueChanged<LearningSeminar> openEvent;

  @override
  State<DiscoverCalendarPage> createState() => _DiscoverCalendarPageState();
}

class _DiscoverCalendarPageState extends State<DiscoverCalendarPage> {
  DateTime? _browsedMonth;
  DateTime get _month {
    final today = widget.today.value;
    return _browsedMonth ?? DateTime(today.year, today.month);
  }

  late Future<List<LearningSeminar>> _events = widget.loadEvents();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<DateTime>(
    valueListenable: widget.today,
    builder: (context, today, _) => Scaffold(
      backgroundColor: calendarPaper,
      appBar: AppBar(
        backgroundColor: calendarPaper,
        leading: const BackButton(),
        title: const Text('Discover calendar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous month',
                        onPressed: () => setState(
                          () => _browsedMonth = DateTime(
                            _month.year,
                            _month.month - 1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMM().format(_month),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: calendarInk),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next month',
                        onPressed: () => setState(
                          () => _browsedMonth = DateTime(
                            _month.year,
                            _month.month + 1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(today),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 630),
                    builder: (context, ink, _) => _monthGrid(today, ink),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<List<LearningSeminar>>(
                    future: _events,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return TextButton.icon(
                          onPressed: () =>
                              setState(() => _events = widget.loadEvents()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Could not load events. Retry'),
                        );
                      }
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final events =
                          (snapshot.data ?? []).where((event) {
                              final date = event.startsAt.toLocal();
                              return date.year == _month.year &&
                                  date.month == _month.month &&
                                  event.status != 'cancelled';
                            }).toList()
                            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
                      bool inPerson(LearningSeminar event) =>
                          event.mode == 'in_person' || event.mode == 'hybrid';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _eventList(
                            'In-person meetings',
                            events.where(inPerson),
                          ),
                          const SizedBox(height: 16),
                          _eventList(
                            'Resource meetings',
                            events.where(
                              (event) =>
                                  event.kind == 'meeting' && !inPerson(event),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _monthGrid(DateTime today, double ink) {
    final offset = calendarOffset(_month);
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final rows = (offset + count + 6) ~/ 7;
    return Table(
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
        for (var row = 0; row < rows; row++)
          TableRow(
            children: [
              for (var col = 0; col < 7; col++)
                _day(row * 7 + col - offset + 1, count, today, ink),
            ],
          ),
      ],
    );
  }

  Widget _day(int day, int count, DateTime today, double ink) {
    if (day < 1 || day > count) return const SizedBox(height: 44);
    final date = DateTime(_month.year, _month.month, day);
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
        height: 44,
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
