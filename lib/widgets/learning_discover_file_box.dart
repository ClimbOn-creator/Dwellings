import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/nova_training_controller.dart';
import '../services/discover_activity.dart';
import '../services/device_location_service.dart';
import 'learning_discover_calendar.dart';
import '../services/learning_service.dart';
import 'learning_discover_office.dart';

const _fileCount = 15;
const _boxWidth = 440.0;
const _boxDepth = 610.0;
const _drawerWall = 152.0;
const _folderHeight = 174.0;
const _tabWidth = 106.0;
const _tabDepth = 27.0;
const _fileRowsDepth = 570.0;
const _manila = Color(0xfff3ebd9);
const _manilaSeam = Color(0xffcdbd9f);
const _palette = [
  Color(0xffe9d7ad),
  Color(0xffd3dfd4),
  Color(0xffd2deea),
  Color(0xffe5d3e7),
  Color(0xffefcec1),
];

double _tabLeft(int index) => 20 + (index % 5) * 73;
Color _fileColor(int index) => _palette[index % _palette.length];
final _numberedFiles = List.generate(
  _fileCount,
  (index) => 'File ${(index + 1).toString().padLeft(2, '0')}',
);

class LearningDiscoverFileBox extends StatefulWidget {
  const LearningDiscoverFileBox({
    super.key,
    this.cabinet = false,
    this.fileNames,
    this.buyerDashboard,
    this.loadEvents,
    this.openEvent,
    this.locate = DeviceLocationService.locate,
  });

  final bool cabinet;
  final List<String>? fileNames;
  final WidgetBuilder? buyerDashboard;
  final Future<List<LearningSeminar>> Function()? loadEvents;
  final ValueChanged<LearningSeminar>? openEvent;
  final DiscoverLocate locate;

  @override
  State<LearningDiscoverFileBox> createState() =>
      _LearningDiscoverFileBoxState();
}

class _LearningDiscoverFileBoxState extends State<LearningDiscoverFileBox>
    with TickerProviderStateMixin {
  final _stageKey = GlobalKey();
  late final _camera = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.cabinet ? 1500 : 820),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 210),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _zoomed = false;
  bool _lampOn = true;
  int? _selected;
  int? _hovered;

  List<String> get _fileNames => widget.fileNames ?? _numberedFiles;

  @override
  void dispose() {
    _camera.dispose();
    _lift.dispose();
    super.dispose();
  }

  void _zoom(bool zoomed) {
    setState(() {
      _zoomed = zoomed;
      _hovered = null;
    });
    _lift.value = 0;
    if (zoomed) {
      _camera.forward();
    } else {
      _camera.reverse();
    }
  }

  void _hover(int index, bool entered) {
    if (_selected != null || (!entered && _hovered != index)) return;
    if (entered && _hovered != index) {
      _hovered = index;
      _lift.value = 0;
    }
    if (entered) {
      _lift.forward();
    } else {
      _lift.reverse();
    }
  }

  Future<void> _open(int index, _BoxView view) async {
    if (_selected != null) return;
    final stage = _stageKey.currentContext!.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final origin = stage.localToGlobal(Offset.zero, ancestor: overlay);
    final source = view
        .fileBounds(
          index,
          _hovered == index ? Curves.easeOut.transform(_lift.value) : 0,
        )
        .shift(origin);
    setState(() => _selected = index);
    DiscoverActivity.record(
      DiscoverActivityKind.files,
      '${widget.cabinet ? 'discover' : 'search'}:$index',
    );
    final route = _DiscoverReaderRoute(
      index: index,
      name: _fileNames[index],
      source: source,
    );
    final guide = NovaTrainingController.instance;
    guide.setFullscreenOverlay(true);
    try {
      await navigator.push(route);
      await route.completed;
    } finally {
      guide.setFullscreenOverlay(false);
    }
    if (!mounted) return;
    setState(() {
      _selected = null;
      _hovered = null;
    });
    _lift.value = 0;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: SizedBox(
        key: _stageKey,
        width: constraints.maxWidth,
        height: math.max(575, constraints.maxHeight),
        child: AnimatedBuilder(
          animation: Listenable.merge([_camera, _lift]),
          builder: (context, _) => LayoutBuilder(
            builder: (context, bounds) {
              final focused = _camera.isCompleted;
              final progress = _camera.value;
              final cabinet = widget.cabinet;
              final drawer = cabinet
                  ? const Interval(
                      0,
                      .43,
                      curve: Curves.easeInOutCubic,
                    ).transform(progress)
                  : 1.0;
              final focus =
                  (cabinet
                          ? const Interval(.43, 1, curve: Curves.easeInOutCubic)
                          : Curves.easeInOutCubic)
                      .transform(progress);
              final size = bounds.biggest;
              final view = _BoxView(
                size,
                focus,
                cabinet: cabinet,
                drawer: drawer,
                fileCount: _fileNames.length,
              );
              final openButton = TextButton(
                onPressed: () => _zoom(true),
                style:
                    TextButton.styleFrom(
                      alignment: Alignment.bottomCenter,
                      padding: EdgeInsets.only(bottom: cabinet ? 5 : 20),
                      shape: const RoundedRectangleBorder(),
                      foregroundColor: const Color(0xff4b443b),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? Colors.black.withValues(alpha: .05)
                            : Colors.transparent,
                      ),
                    ),
                child: cabinet
                    ? const SizedBox.shrink()
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Explore the file box'),
                      ),
              );
              return Stack(
                children: [
                  if (cabinet && focus < 1)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 1 - focus,
                        child: DiscoverOffice(
                          key: const ValueKey('discover-office'),
                          drawer: drawer,
                          interactive: _camera.isDismissed,
                          lampOn: _lampOn,
                          toggleLamp: () => setState(() => _lampOn = !_lampOn),
                          openLearning: () => _zoom(true),
                          locate: widget.locate,
                          buyerDashboard: widget.buyerDashboard,
                          loadEvents: widget.loadEvents,
                          openEvent: widget.openEvent,
                        ),
                      ),
                    ),
                  if (drawer > 0)
                    Positioned.fill(
                      child: Opacity(
                        opacity: (drawer * 4).clamp(0.0, 1.0),
                        child: CustomPaint(
                          key: const ValueKey('learning-folder-collection'),
                          painter: _FileBoxPainter(
                            view,
                            _hovered,
                            _lift.value,
                            _selected,
                            _fileNames,
                          ),
                        ),
                      ),
                    ),
                  if (!_zoomed && _camera.isDismissed)
                    if (cabinet)
                      Positioned.fromRect(
                        rect: discoverCabinetHitArea(size),
                        child: Semantics(
                          label: 'Open filing cabinet',
                          child: openButton,
                        ),
                      )
                    else
                      Positioned.fill(child: openButton),
                  if (focused)
                    for (var i = 0; i < _fileNames.length; i++)
                      Positioned.fromRect(
                        rect: view.rowBounds(i),
                        child: TextButton(
                          onPressed: _selected != null
                              ? null
                              : () => _open(i, view),
                          onHover: (hovered) => _hover(i, hovered),
                          onFocusChange: (focused) => _hover(i, focused),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(),
                            foregroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.transparent,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(_fileNames[i]),
                        ),
                      ),
                  if (focused && cabinet && _selected == null)
                    _DrawerHint(drawer: view.silhouette),
                  if (focused)
                    Positioned(
                      top: 4,
                      right: 8,
                      child: IconButton(
                        onPressed: () => _zoom(false),
                        tooltip: cabinet
                            ? 'Close filing cabinet'
                            : 'Zoom out of the file box',
                        icon: const Icon(Icons.zoom_out_map),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _DrawerHint extends StatelessWidget {
  const _DrawerHint({required this.drawer});

  final Rect drawer;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xff514940);
    const label = Text(
      'Click on any file that interests you',
      textAlign: TextAlign.center,
      style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w600),
    );
    if (drawer.left >= 240) {
      return Positioned(
        left: drawer.left - 232,
        top: drawer.top + drawer.height * .28,
        width: 226,
        child: const IgnorePointer(
          child: Row(
            children: [
              Expanded(child: label),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: ink, size: 25),
            ],
          ),
        ),
      );
    }
    return Positioned(
      left: 48,
      right: 48,
      top: 1,
      height: drawer.top - 2,
      child: const IgnorePointer(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label,
              Icon(Icons.arrow_downward, color: ink, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxView {
  _BoxView(
    this.size,
    this.focus, {
    required this.cabinet,
    required this.drawer,
    required int fileCount,
  }) : _rowDepth = _fileRowsDepth / fileCount {
    final yaw = cabinet ? 0.0 : .43 * (1 - focus);
    final restPitch = cabinet ? .34 : .53;
    final pitch = restPitch + (math.pi / 2 - restPitch) * focus;
    _sinYaw = math.sin(yaw);
    _cosYaw = math.cos(yaw);
    _sinPitch = math.sin(pitch);
    _cosPitch = math.cos(pitch);
    final corners = [
      for (final x in [0.0, _boxWidth])
        for (final y in [0.0, _folderHeight + 24])
          for (final z in [0.0, _boxDepth]) _project(x, y, z),
    ];
    final bounds = _bounds(corners);

    final closeUp = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.max(1, size.width - 28),
      height: math.max(1, size.height - 88),
    );
    final overview = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: closeUp.width * .68,
      height: closeUp.height * .68,
    );
    final viewport = Rect.lerp(overview, closeUp, focus)!;
    final fit = math.min(
      viewport.width / bounds.width,
      viewport.height / bounds.height,
    );
    final centered = viewport.center - bounds.center * fit;
    if (cabinet) {
      final front = discoverDrawerFront(size, drawer);
      final anchoredScale = front.width / _boxWidth;
      final anchored =
          front.topLeft - _project(0, _drawerWall, _boxDepth) * anchoredScale;
      _scale = anchoredScale + (fit - anchoredScale) * focus;
      _offset = Offset.lerp(anchored, centered, focus)!;
    } else {
      _scale = fit;
      _offset = centered;
    }
    silhouette = Rect.fromPoints(
      bounds.topLeft * _scale + _offset,
      bounds.bottomRight * _scale + _offset,
    );
  }

  final Size size;
  final double focus, drawer;
  final bool cabinet;
  final double _rowDepth;
  late final double _sinYaw, _cosYaw, _sinPitch, _cosPitch, _scale;
  late final Offset _offset;
  late final Rect silhouette;

  static Rect _bounds(List<Offset> points) => Rect.fromLTRB(
    points.map((p) => p.dx).reduce(math.min),
    points.map((p) => p.dy).reduce(math.min),
    points.map((p) => p.dx).reduce(math.max),
    points.map((p) => p.dy).reduce(math.max),
  );

  Offset _project(double x, double y, double z) => Offset(
    x * _cosYaw - z * _sinYaw,
    (x * _sinYaw + z * _cosYaw) * _sinPitch - y * _cosPitch,
  );

  Offset point(double x, double y, double z) =>
      _project(x, y, z) * _scale + _offset;

  double rail(int index) => 24 + index * _rowDepth;

  Rect rowBounds(int index) => Rect.fromPoints(
    point(8, _folderHeight, rail(index) - 3),
    point(_boxWidth - 8, _folderHeight, rail(index) + _rowDepth - 4),
  );

  Rect fileBounds(int index, double lift) => Rect.fromPoints(
    point(8, _folderHeight + lift * 25, rail(index) - 3 - lift * 5),
    point(_boxWidth - 8, _folderHeight, rail(index) + _tabDepth - lift * 5),
  );
}

class _FileBoxPainter extends CustomPainter {
  const _FileBoxPainter(
    this.view,
    this.hovered,
    this.lift,
    this.selected,
    this.fileNames,
  );

  final _BoxView view;
  final int? hovered;
  final double lift;
  final int? selected;
  final List<String> fileNames;

  @override
  void paint(Canvas canvas, Size size) {
    const wall = _drawerWall;
    if (view.cabinet) {
      canvas.clipRect(
        Rect.fromLTRB(
          0,
          discoverDeskUnderside(size) * (1 - view.focus),
          size.width,
          size.height,
        ),
      );
    }
    final p = view.point;
    void face(Color color, List<Offset> vertices) {
      final path = Path()..addPolygon(vertices, true);
      canvas.drawPath(path, Paint()..color = color);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: view.silhouette.bottomCenter.translate(
          0,
          -view.silhouette.height * .08,
        ),
        width: view.silhouette.width * .94,
        height: view.silhouette.height * .16,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .30 * (1 - view.focus))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    face(const Color(0xff47382a), [
      p(0, wall, 0),
      p(_boxWidth, wall, 0),
      p(_boxWidth, wall, _boxDepth),
      p(0, wall, _boxDepth),
    ]);
    final emerge = const Interval(
      .24,
      1,
      curve: Curves.easeOutCubic,
    ).transform(view.drawer);
    for (var i = 0; i < fileNames.length; i++) {
      if (i == selected || emerge == 0) continue;
      final raised = i == hovered ? Curves.easeOut.transform(lift) : 0.0;
      final z = view.rail(i) - raised * 5;
      final h = _folderHeight - (1 - emerge) * 105 + raised * 25;
      final color = _fileColor(i);
      final x = _tabLeft(i);
      face(Color.lerp(color, const Color(0xff493f35), .48)!, [
        p(10, 14, z),
        p(_boxWidth - 10, 14, z),
        p(_boxWidth - 10, h, z),
        p(10, h, z),
      ]);
      face(_manilaSeam, [
        p(7, h, z),
        p(_boxWidth - 7, h, z),
        p(_boxWidth - 7, h, z + 8),
        p(7, h, z + 8),
      ]);
      face(color, [
        p(x, h + 17, z),
        p(x + _tabWidth, h + 17, z),
        p(x + _tabWidth, h, z + _tabDepth),
        p(x, h, z + _tabDepth),
      ]);
      if (view.focus > .35) {
        final label = TextPainter(
          text: TextSpan(
            text: fileNames[i],
            style: TextStyle(
              fontFamily: 'PactInter',
              color: const Color(
                0xff2a211c,
              ).withValues(alpha: ((view.focus - .35) / .65).clamp(0.0, 1.0)),
              fontSize: (13 * view._scale).clamp(8.0, 15.0),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final center = p(x + _tabWidth / 2, h + 8, z + _tabDepth / 2);
        final tabWidth = (p(x + _tabWidth, h, z) - p(x, h, z)).distance;
        final textScale = math.min(1.0, tabWidth * .9 / label.width);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(textScale);
        label.paint(canvas, Offset(-label.width / 2, -label.height / 2));
        canvas.restore();
        label.dispose();
      }
    }
    final side = view.cabinet ? 0.0 : _boxWidth;
    face(view.cabinet ? discoverDrawerSide : const Color(0xffb58253), [
      p(side, 0, 0),
      p(side, wall, 0),
      p(side, wall, _boxDepth),
      p(side, 0, _boxDepth),
    ]);
    face(view.cabinet ? discoverDrawerFace : const Color(0xffd4a475), [
      p(0, 0, _boxDepth),
      p(_boxWidth, 0, _boxDepth),
      p(_boxWidth, wall, _boxDepth),
      p(0, wall, _boxDepth),
    ]);
    if (view.cabinet) {
      face(const Color(0xff30332f), [
        p(157, 96, _boxDepth),
        p(283, 96, _boxDepth),
        p(283, 130, _boxDepth),
        p(157, 130, _boxDepth),
      ]);
      face(const Color(0xffe9e2d2), [
        p(166, 104, _boxDepth),
        p(274, 104, _boxDepth),
        p(274, 122, _boxDepth),
        p(166, 122, _boxDepth),
      ]);
      face(const Color(0xff2c2f2b), [
        p(171, 42, _boxDepth),
        p(269, 42, _boxDepth),
        p(269, 61, _boxDepth),
        p(171, 61, _boxDepth),
      ]);
      face(const Color(0xffab827b), [
        p(28, 60, _boxDepth),
        p(84, 64, _boxDepth),
        p(87, 86, _boxDepth),
        p(74, 84, _boxDepth),
        p(62, 91, _boxDepth),
        p(28, 87, _boxDepth),
      ]);
    }
    final rim = Paint()
      ..color = view.cabinet ? discoverDrawerRim : const Color(0xffe5bc8d)
      ..strokeWidth = math.max(1, 7 * view._scale)
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()..addPolygon([
        p(0, wall, 0),
        p(_boxWidth, wall, 0),
        p(_boxWidth, wall, _boxDepth),
        p(0, wall, _boxDepth),
      ], true),
      rim,
    );
  }

  @override
  bool shouldRepaint(_FileBoxPainter oldDelegate) =>
      oldDelegate.view != view ||
      oldDelegate.hovered != hovered ||
      oldDelegate.lift != lift ||
      oldDelegate.selected != selected;
}

// The click-driven transitions show how the file box and reader fit together.
class _DiscoverReaderRoute extends PageRouteBuilder<void> {
  _DiscoverReaderRoute({
    required int index,
    required String name,
    required Rect source,
  }) : super(
         opaque: false,
         transitionDuration: const Duration(milliseconds: 1950),
         reverseTransitionDuration: const Duration(milliseconds: 1250),
         pageBuilder: (_, animation, _) => _DiscoverReader(
           index: index,
           name: name,
           source: source,
           animation: animation,
         ),
       );

  @override
  AnimationController createAnimationController() => AnimationController(
    vsync: navigator!,
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
}

class _DiscoverReader extends StatelessWidget {
  const _DiscoverReader({
    required this.index,
    required this.name,
    required this.source,
    required this.animation,
  });

  final int index;
  final String name;
  final Rect source;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final folderWidth = math.min(size.width * .75, 680.0);
            final folderHeight = math.min(size.height * .48, folderWidth * .72);
            final center = size.center(Offset(0, size.height * .12));
            final openFolder = Rect.fromCenter(
              center: center,
              width: folderWidth,
              height: folderHeight,
            );
            final sheetStart = Rect.fromCenter(
              center: center.translate(0, folderHeight * .02),
              width: folderWidth * .74,
              height: folderHeight * .77,
            );
            final sheetTop = sheetStart.shift(Offset(0, -folderHeight * .67));
            final left = Rect.fromLTWH(0, 0, size.width / 2, size.height);
            final right = left.shift(Offset(size.width / 2, 0));
            final color = _fileColor(index);
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final time = animation.value;
                double phase(
                  double start,
                  double end, [
                  Curve curve = Curves.easeInOutCubic,
                ]) => Interval(start, end, curve: curve).transform(time);

                final extracted = phase(0, .36);
                final folder = Rect.lerp(source, openFolder, extracted)!.shift(
                  Offset(
                    0,
                    -math.sin(extracted * math.pi) * folderHeight * .38,
                  ),
                );
                final flap = phase(.27, .55);
                final spread = phase(.63, 1);
                final folderOpacity = 1 - phase(.73, .94);
                final opened = time == 1;

                Widget sheet(String label, Rect target, {required bool video}) {
                  final direction = video ? 1.0 : -1.0;
                  final rise = video ? phase(.46, .70) : phase(.39, .65);
                  final lifted = Rect.lerp(sheetStart, sheetTop, rise)!.shift(
                    Offset(
                      direction * folderWidth * (.027 + .13 * rise),
                      video ? 12 : 0,
                    ),
                  );
                  return Positioned.fromRect(
                    rect: Rect.lerp(lifted, target, spread)!,
                    child: Transform.rotate(
                      angle: direction * .13 * rise * (1 - spread),
                      child: Opacity(
                        opacity: rise == 0
                            ? 0
                            : phase(video ? .46 : .39, video ? .54 : .47),
                        child: _DiscoverSheet(
                          key: ValueKey('discover-$label-pane'),
                          label: label,
                          video: video,
                          color: color,
                          spread: spread,
                          opened: opened,
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(
                          alpha: .34 * phase(0, .46),
                        ),
                      ),
                    ),
                    if (folderOpacity > 0)
                      Positioned.fromRect(
                        rect: folder,
                        child: Opacity(
                          opacity: folderOpacity,
                          child: _ReaderFolderFace(
                            color: color,
                            index: index,
                            name: name,
                            back: true,
                          ),
                        ),
                      ),
                    if (time > .46) sheet('Video', right, video: true),
                    if (time > .39) sheet('Text', left, video: false),
                    if (folderOpacity > 0)
                      Positioned.fromRect(
                        rect: folder,
                        child: Opacity(
                          opacity: folderOpacity,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, .001)
                              ..rotateX(flap * 1.21),
                            child: _ReaderFolderFace(
                              color: color,
                              index: index,
                              name: name,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SafeArea(
                        minimum: const EdgeInsets.all(12),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xfff0ede6),
                            foregroundColor: const Color(0xff423d34),
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                          tooltip: 'Close file',
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

class _ReaderFolderFace extends StatelessWidget {
  const _ReaderFolderFace({
    required this.color,
    required this.index,
    required this.name,
    this.back = false,
  });

  final Color color;
  final int index;
  final String name;
  final bool back;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final tabWidth = width * _tabWidth / (_boxWidth - 16);
      return Stack(
        children: [
          if (back)
            Positioned(
              left: width * (_tabLeft(index) - 8) / (_boxWidth - 16),
              top: 0,
              width: tabWidth,
              height: height * .16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.black12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xff332d24),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            top: height * (back ? .13 : .23),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: back
                      ? const [Color(0xffe0d2b7), Color(0xffc6b492)]
                      : const [Color(0xfffff8e9), _manila, Color(0xffe7d7b9)],
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _manilaSeam),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 19,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: back
                  ? null
                  : Stack(
                      children: [
                        Positioned(
                          left: width * .045,
                          top: height * .035,
                          width: width * .13,
                          height: math.min(height * .035, 6),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 1,
                          right: 1,
                          bottom: height * .065,
                          child: const Divider(height: 1, color: _manilaSeam),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    },
  );
}

class _DiscoverSheet extends StatelessWidget {
  const _DiscoverSheet({
    required this.label,
    required this.video,
    required this.color,
    required this.spread,
    required this.opened,
    super.key,
  });

  final String label;
  final bool video;
  final Color color;
  final double spread;
  final bool opened;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: video ? const Color(0xfff6f4ef) : Colors.white,
      borderRadius: BorderRadius.circular(8 * (1 - spread)),
      border: Border.all(
        color: const Color(0xffa0937c).withValues(alpha: .46 * (1 - spread)),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .23 * (1 - spread)),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: opened
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 4, color: color),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    Icon(
                      video
                          ? Icons.videocam_outlined
                          : Icons.description_outlined,
                      color: const Color(0xff6a6051),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xff514a3e),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xffe8e2d8)),
              if (!video)
                const Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(width: double.infinity),
                  ),
                ),
            ],
          )
        : null,
  );
}
