import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/business_sale_bulletin_service.dart';
import '../services/deal_room_service.dart';
import '../services/discover_activity.dart';
import '../services/learning_service.dart';
import 'learning_discover_portal.dart';

enum _Tracker {
  files('Files opened', Color(0xfff1dda0)),
  concepts('Concepts completed', Color(0xffe7e8cf)),
  rsvps('Upcoming RSVPs', Color(0xffc4d8df)),
  starter('Best 5 files', Color(0xffe1c9dc)),
  views('Deals viewed', Color(0xffe8bfb0)),
  saves('Saved listings', Color(0xfff7e3c4)),
  rooms('Active deal rooms', Color(0xffd7d3e6)),
  team('My team', Color(0xffd3dfae)),
  tasks('Deal tasks done', Color(0xfff5eccf)),
  blocked('Blocked tasks', Color(0xffe9c6bd)),
  closing('Next target close', Color(0xffbed8d5)),
  intros('Pending introductions', Color(0xffecdb9c));

  const _Tracker(this.label, this.color);
  final String label;
  final Color color;
}

typedef _Reading = ({String value, List<String> details});

_Reading _reading(Object value, [List<String> details = const []]) =>
    (value: value.toString(), details: details);

const _ink = Color(0xff332b23);
const _slants = [
  -.067,
  .024,
  -.028,
  .082,
  .037,
  -.044,
  .055,
  -.06,
  -.024,
  .067,
  -.041,
  .025,
];
const _pins = [Color(0xff9c3d34), Color(0xff2f6656), Color(0xff344c77)];

class DiscoverPinboard extends StatelessWidget {
  const DiscoverPinboard({super.key})
    : aspect = 1.6,
      compact = false,
      writing = 0,
      readings = const {},
      openNote = null,
      signedIn = false;

  const DiscoverPinboard._zoomed({
    required this.aspect,
    required this.compact,
    required this.writing,
    required this.readings,
    required this.openNote,
    required this.signedIn,
  });

  final double aspect, writing;
  final bool compact, signedIn;
  final Map<_Tracker, _Reading> readings;
  final ValueChanged<_Tracker>? openNote;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspect,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final width = bounds.maxWidth;
        final height = bounds.maxHeight;
        final columns = compact ? 3 : 4;
        final rows = compact ? 4 : 3;
        final columnWidth = width * .88 / columns;
        final rowHeight = height * .85 / rows;
        return CustomPaint(
          painter: const _CorkAndPapers(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tracker in _Tracker.values)
                Positioned(
                  left:
                      width * .061 +
                      columnWidth * (tracker.index % columns) +
                      width * (tracker.index.isEven ? -.007 : .009),
                  top:
                      height * .068 +
                      rowHeight * (tracker.index ~/ columns) +
                      height * ((tracker.index % 3) - 1) * .016,
                  width: columnWidth * .94,
                  height: rowHeight * .88,
                  child: Transform.rotate(
                    angle: _slants[tracker.index],
                    child: _PinnedNote(
                      tracker: tracker,
                      reading: readings[tracker],
                      writing: writing,
                      signedIn: signedIn,
                      open: openNote == null ? null : () => openNote!(tracker),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _PinnedNote extends StatelessWidget {
  const _PinnedNote({
    required this.tracker,
    required this.reading,
    required this.writing,
    required this.signedIn,
    required this.open,
  });
  final _Tracker tracker;
  final _Reading? reading;
  final double writing;
  final bool signedIn;
  final VoidCallback? open;

  @override
  Widget build(BuildContext context) {
    final progress = ((writing - tracker.index * .028) / .55).clamp(0.0, 1.0);
    final title = tracker.label;
    final written = title.substring(0, (title.length * progress).floor());
    final value =
        reading?.value ??
        (tracker == _Tracker.starter
            ? 'Coming soon'
            : signedIn
            ? '…'
            : '—');
    final detail = reading?.details.firstOrNull;
    return LayoutBuilder(
      builder: (context, bounds) {
        final unit = math.min(bounds.maxWidth, bounds.maxHeight);
        final font = (unit * .126).clamp(10.0, 26.0);
        return Material(
          color: tracker.color,
          elevation: 3,
          shadowColor: const Color(0x9951321d),
          child: InkWell(
            onTap: open,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? const Color(0x243e301d)
                  : Colors.transparent,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _PaperRuling(tracker.index)),
                ),
                Positioned(
                  left: bounds.maxWidth * .46,
                  top: unit * .051,
                  child: _Pin(unit * .085, _pins[tracker.index % _pins.length]),
                ),
                if (progress > 0)
                  Positioned.fill(
                    top: unit * .175,
                    left: unit * .066,
                    right: unit * .066,
                    bottom: unit * .035,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: bounds.maxWidth - unit * .132,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              progress == 1 ? title : '$written▏',
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _ink,
                                fontSize: font,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (progress > .86) ...[
                              SizedBox(height: unit * .029),
                              Text(
                                value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _ink,
                                  height: 1.03,
                                  fontSize:
                                      font * (value.length < 5 ? 1.75 : 1.18),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (detail != null && bounds.maxWidth >= 112)
                                Text(
                                  detail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: font * .78,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-.4, -.55),
        colors: [Color.lerp(color, Colors.white, .38)!, color],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66412c20),
          offset: Offset(1, 2),
          blurRadius: 2,
        ),
      ],
    ),
  );
}

class _PaperRuling extends CustomPainter {
  const _PaperRuling(this.index);
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x13553a24);
    if (index % 3 == 0) {
      for (var i = 1; i < 8; i++) {
        final y = size.height * i / 8;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (index % 3 == 1) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * .15),
        paint,
      );
    }
    canvas.drawPath(
      Path()..addPolygon([
        Offset(size.width * .87, size.height),
        Offset(size.width, size.height * .80),
        Offset(size.width, size.height),
      ], true),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PaperRuling oldDelegate) => oldDelegate.index != index;
}

class _CorkAndPapers extends CustomPainter {
  const _CorkAndPapers();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint();
    canvas.drawRect(
      Rect.fromLTWH(w * .004, h * .009, w, h),
      paint..color = const Color(0x42513926),
    );
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xff78492e));
    canvas.drawRect(
      (Offset.zero & size).deflate(h * .013),
      paint..color = const Color(0xffbf8d56),
    );
    final cork = (Offset.zero & size).deflate(h * .024);
    canvas.drawRect(cork, paint..color = const Color(0xffa46f43));
    final random = math.Random(433);
    for (var i = 0; i < 2200; i++) {
      final point = Offset(
        cork.left + random.nextDouble() * cork.width,
        cork.top + random.nextDouble() * cork.height,
      );
      canvas.drawCircle(
        point,
        h * (.0006 + random.nextDouble() * .0018),
        paint
          ..color = i.isEven
              ? const Color(0x33462619)
              : const Color(0x33ffcb83),
      );
    }
    const papers = [
      (.17, .26, .26, .40, -.19, Color(0xffd9c5a1), 0),
      (.47, .20, .54, .18, .022, Color(0xffe9e3d4), 1),
      (.80, .30, .29, .45, .24, Color(0xffa8a8c6), 2),
      (.28, .66, .36, .45, -.087, Color(0xffe4e0c8), 2),
      (.72, .65, .43, .41, .11, Color(0xffe9e0cf), 1),
      (.44, .72, .25, .39, -.17, Color(0xff72928e), 2),
      (.16, .81, .21, .27, -.105, Color(0xffa58f71), 2),
      (.88, .78, .12, .31, .19, Color(0xffdacf96), 0),
    ];
    canvas.save();
    canvas.clipRect(cork);
    for (final (x, y, width, height, tilt, color, print) in papers) {
      canvas.save();
      canvas.translate(x * w, y * h);
      canvas.rotate(tilt);
      final paper = Rect.fromCenter(
        center: Offset.zero,
        width: width * w,
        height: height * h,
      );
      canvas.drawRect(
        paper.shift(Offset(h * .004, h * .008)),
        paint..color = const Color(0x70563926),
      );
      canvas.drawRect(paper, paint..color = color);
      final inner = paper.deflate(h * .022);
      if (print == 2) {
        final photo = Rect.fromLTWH(
          inner.left,
          inner.top,
          inner.width,
          inner.height * .48,
        );
        canvas.drawRect(photo, paint..color = const Color(0x77556554));
        canvas.drawPath(
          Path()..addPolygon([
            photo.bottomLeft,
            photo.centerLeft,
            photo.center.translate(0, -photo.height * .25),
            photo.bottomRight,
          ], true),
          paint..color = const Color(0x66823f2c),
        );
      }
      final columns = print == 1 ? 3 : 1;
      for (var col = 0; col < columns; col++) {
        for (var line = print == 2 ? 8 : 0; line < 16; line++) {
          final column = inner.width / columns;
          final y = inner.top + inner.height * line / 16;
          canvas.drawLine(
            Offset(inner.left + column * col, y),
            Offset(
              inner.left + column * (col + .46 + random.nextDouble() * .48),
              y,
            ),
            paint
              ..color = const Color(0x4859493c)
              ..strokeWidth = h * .0018,
          );
        }
      }
      final pin = Offset(paper.center.dx, paper.top + h * .014);
      canvas.drawCircle(
        pin.translate(h * .003, h * .003),
        h * .006,
        paint..color = const Color(0x55543921),
      );
      canvas.drawCircle(pin, h * .006, paint..color = _pins[print]);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CorkAndPapers oldDelegate) => false;
}

class DiscoverPinboardRoute extends PageRouteBuilder<void> {
  DiscoverPinboardRoute(Rect source)
    : super(
        opaque: false,
        transitionDuration: discoverPaperDuration,
        reverseTransitionDuration: discoverPaperReverseDuration,
        pageBuilder: (_, animation, _) =>
            _ZoomedPinboard(source: source, animation: animation),
      );

  @override
  AnimationController createAnimationController() => AnimationController(
    vsync: navigator!,
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
}

class _ZoomedPinboard extends StatefulWidget {
  const _ZoomedPinboard({required this.source, required this.animation});
  final Rect source;
  final Animation<double> animation;

  @override
  State<_ZoomedPinboard> createState() => _ZoomedPinboardState();
}

class _ZoomedPinboardState extends State<_ZoomedPinboard> {
  final _readings = ValueNotifier<Map<_Tracker, _Reading>>({});
  String? _account;
  Timer? _timer;
  StreamSubscription<Object?>? _auth;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _account = BackendService.user?.id;
    _auth = BackendService.authChanges?.listen((_) => _accountChanged());
    DiscoverActivity.changes.addListener(_refreshActivity);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  void _accountChanged() {
    final account = BackendService.user?.id;
    if (account == _account) return;
    setState(() {
      _account = account;
      _refreshing = false;
      _readings.value = {};
    });
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth?.cancel();
    DiscoverActivity.changes.removeListener(_refreshActivity);
    _readings.dispose();
    super.dispose();
  }

  bool _owns(String account) =>
      mounted && _account == account && BackendService.user?.id == account;

  Future<void> _read(
    String account,
    List<_Tracker> trackers,
    Future<Map<_Tracker, _Reading>> Function() load,
  ) async {
    Map<_Tracker, _Reading> data;
    try {
      data = await load();
    } catch (_) {
      data = {for (final tracker in trackers) tracker: _reading('Unavailable')};
    }
    if (_owns(account)) _readings.value = {..._readings.value, ...data};
  }

  Future<void> _refreshActivity() async {
    final account = _account;
    if (account == null) return;
    await _read(
      account,
      [_Tracker.files, _Tracker.views],
      () async => {
        _Tracker.files: _reading(
          await DiscoverActivity.count(account, DiscoverActivityKind.files),
        ),
        _Tracker.views: _reading(
          await DiscoverActivity.count(account, DiscoverActivityKind.deals),
        ),
      },
    );
  }

  Future<void> _refresh() async {
    final account = _account;
    if (account == null || _refreshing) return;
    _refreshing = true;
    await Future.wait([
      _refreshActivity(),
      _read(
        account,
        [_Tracker.concepts],
        () async => {
          _Tracker.concepts: _reading(
            (await LearningService.progress()).length,
          ),
        },
      ),
      _read(account, [_Tracker.team], () async {
        final team = await AccountService.loadTeam();
        return {
          _Tracker.team: _reading(team.length, [
            for (final member in team)
              [
                member.name,
                member.jobTitle,
                member.company,
              ].where((part) => part.isNotEmpty).join(' · '),
          ]),
        };
      }),
      _read(account, [_Tracker.rsvps], () async {
        final now = DateTime.now();
        final rsvps =
            (await LearningService.seminars())
                .where(
                  (event) =>
                      event.registered &&
                      event.startsAt.isAfter(now) &&
                      event.status != 'cancelled' &&
                      event.status != 'ended',
                )
                .toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        return {
          _Tracker.rsvps: _reading(rsvps.length, [
            for (final event in rsvps)
              '${event.title} · ${DateFormat.MMMd().add_jm().format(event.startsAt.toLocal())}',
          ]),
        };
      }),
      _read(account, [_Tracker.saves], () async {
        final saved = (await BusinessSaleBulletinService.load(
          includeExamples: true,
        )).where((listing) => listing.isSaved).toList();
        return {
          _Tracker.saves: _reading(saved.length, [
            for (final listing in saved) listing.title,
          ]),
        };
      }),
      _read(account, [_Tracker.intros], () async {
        final pending = (await AccountService.loadOutgoingIntroductions())
            .where((request) => request.status == 'new')
            .toList();
        return {
          _Tracker.intros: _reading(pending.length, [
            for (final request in pending) request.providerName,
          ]),
        };
      }),
      _read(
        account,
        [_Tracker.rooms, _Tracker.tasks, _Tracker.blocked, _Tracker.closing],
        () async {
          final today = DateUtils.dateOnly(DateTime.now());
          final rooms = (await DealRoomService.loadRooms())
              .where(
                (room) =>
                    room.archivedAt == null && room.currentStage != 'complete',
              )
              .toList();
          final closings =
              rooms
                  .where(
                    (room) =>
                        room.targetCloseDate != null &&
                        !room.targetCloseDate!.isBefore(today),
                  )
                  .toList()
                ..sort(
                  (a, b) => a.targetCloseDate!.compareTo(b.targetCloseDate!),
                );
          final done = rooms.fold(
            0,
            (sum, room) => sum + room.completedTaskCount,
          );
          final total = rooms.fold(0, (sum, room) => sum + room.totalTaskCount);
          return {
            _Tracker.rooms: _reading(rooms.length, [
              for (final room in rooms) room.title,
            ]),
            _Tracker.tasks: _reading('$done / $total', [
              for (final room in rooms)
                '${room.title} · ${room.completedTaskCount} of ${room.totalTaskCount}',
            ]),
            _Tracker.blocked: _reading(
              rooms.fold<int>(0, (sum, room) => sum + room.blockedTaskCount),
              [
                for (final room in rooms.where(
                  (room) => room.blockedTaskCount > 0,
                ))
                  '${room.title} · ${room.blockedTaskCount} blocked',
              ],
            ),
            _Tracker.closing: _reading(
              closings.isEmpty
                  ? 'None set'
                  : DateFormat.MMMd().format(closings.first.targetCloseDate!),
              [
                for (final room in closings)
                  '${room.title} · ${DateFormat.yMMMd().format(room.targetCloseDate!)}',
              ],
            ),
          };
        },
      ),
    ]);
    if (_owns(account)) _refreshing = false;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.animation,
    builder: (context, _) {
      final time = widget.animation.value;
      final zoom = discoverPaperZoom.transform(time);
      final ink = const Interval(.47, 1).transform(time);
      return LayoutBuilder(
        builder: (context, bounds) {
          final size = bounds.biggest;
          final compact = size.width < 650;
          final aspect = compact ? .97 : 1.6;
          final width = math.max(
            1.0,
            math.min(size.width - 22, (size.height - 64) * aspect),
          );
          final target = Rect.fromCenter(
            center: size.center(const Offset(0, 23)),
            width: width,
            height: width / aspect,
          );
          final rect = Rect.lerp(widget.source, target, zoom)!;
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(
                    0xfff4eee4,
                  ).withValues(alpha: discoverPaperBackdrop.transform(time)),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: ValueListenableBuilder(
                  valueListenable: _readings,
                  builder: (context, data, _) => DiscoverPinboard._zoomed(
                    aspect: rect.width / rect.height,
                    compact: compact && zoom > .65,
                    writing: ink,
                    readings: _account == BackendService.user?.id
                        ? data
                        : const {},
                    signedIn: _account != null,
                    openNote: time == 1 ? _openNote : null,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: IgnorePointer(
                    ignoring: time < 1,
                    child: Opacity(
                      opacity: const Interval(.7, 1).transform(time),
                      child: Material(
                        type: MaterialType.transparency,
                        child: SizedBox(
                          height: 46,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: BackButton(),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Discover pinboard',
                                    style: TextStyle(
                                      fontSize: 20,
                                      height: 1.15,
                                    ),
                                  ),
                                  if (_account == null)
                                    const Text(
                                      'Sign in to see your trackers',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.15,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  Future<void> _openNote(_Tracker tracker) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: tracker.color,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tracker.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close note',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: ValueListenableBuilder(
                  valueListenable: _readings,
                  builder: (context, data, _) {
                    if (tracker == _Tracker.starter) {
                      return const Text(
                        'Your starter-file recommendations are coming soon.',
                      );
                    }
                    if (_account == null ||
                        _account != BackendService.user?.id) {
                      return const Text(
                        'Sign in to see your activity and team.',
                      );
                    }
                    final reading = data[tracker];
                    if (reading == null)
                      return const CircularProgressIndicator();
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        Text(
                          reading.value,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        for (final detail in reading.details)
                          Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Text(detail),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
