import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/nova_training_controller.dart';

const _fileCount = 15;
const _boxWidth = 440.0;
const _boxDepth = 610.0;
const _folderHeight = 174.0;
const _tabWidth = 106.0;
const _tabDepth = 27.0;
const _step = 38.0;
const _palette = [
  Color(0xffe9d7ad),
  Color(0xffd3dfd4),
  Color(0xffd2deea),
  Color(0xffe5d3e7),
  Color(0xffefcec1),
];

double _rail(int index) => 24 + index * _step;
double _tabLeft(int index) => 20 + (index % 5) * 73;
Color _fileColor(int index) => _palette[index % _palette.length];
String _fileName(int index) => 'File ${(index + 1).toString().padLeft(2, '0')}';

class LearningDiscoverFileBox extends StatefulWidget {
  const LearningDiscoverFileBox({super.key});

  @override
  State<LearningDiscoverFileBox> createState() =>
      _LearningDiscoverFileBoxState();
}

class _LearningDiscoverFileBoxState extends State<LearningDiscoverFileBox>
    with TickerProviderStateMixin {
  final _stageKey = GlobalKey();
  late final _camera = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 210),
  );
  bool _zoomed = false;
  int? _selected;
  int? _hovered;

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
    if (MediaQuery.disableAnimationsOf(context)) {
      _camera.value = zoomed ? 1 : 0;
    } else if (zoomed) {
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
    if (MediaQuery.disableAnimationsOf(context)) {
      _lift.value = entered ? 1 : 0;
    } else if (entered) {
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() => _selected = index);
    final route = PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 1600),
      reverseTransitionDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 1050),
      pageBuilder: (_, animation, _) =>
          _DiscoverReader(index: index, source: source, animation: animation),
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
              final view = _BoxView(
                bounds.biggest,
                Curves.easeInOutCubic.transform(_camera.value),
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FileBoxPainter(
                        view,
                        _hovered,
                        _lift.value,
                        _selected,
                      ),
                    ),
                  ),
                  if (!_zoomed)
                    Positioned.fill(
                      child: TextButton(
                        onPressed: () => _zoom(true),
                        style:
                            TextButton.styleFrom(
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.only(bottom: 20),
                              foregroundColor: const Color(0xff4b443b),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.focused)
                                    ? Colors.black.withValues(alpha: .04)
                                    : Colors.transparent,
                              ),
                            ),
                        child: const Text('Explore the file box'),
                      ),
                    ),
                  if (focused)
                    for (var i = 0; i < _fileCount; i++)
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
                          child: Text(_fileName(i)),
                        ),
                      ),
                  if (focused)
                    Positioned(
                      top: 4,
                      right: 8,
                      child: IconButton(
                        onPressed: () => _zoom(false),
                        tooltip: 'Zoom out of the file box',
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

class _BoxView {
  _BoxView(this.size, this.focus) {
    final yaw = .43 * (1 - focus);
    final pitch = .53 + (math.pi / 2 - .53) * focus;
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
    _scale =
        math.min(
          (size.width - 28) / bounds.width,
          (size.height - 88) / bounds.height,
        ) *
        (.68 + .32 * focus);
    _offset = size.center(Offset.zero) - bounds.center * _scale;
  }

  final Size size;
  final double focus;
  late final double _sinYaw, _cosYaw, _sinPitch, _cosPitch, _scale;
  late final Offset _offset;

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

  Rect rowBounds(int index) => Rect.fromPoints(
    point(8, _folderHeight, _rail(index) - 3),
    point(_boxWidth - 8, _folderHeight, _rail(index) + _step - 4),
  );

  Rect fileBounds(int index, double lift) => Rect.fromPoints(
    point(8, _folderHeight + lift * 25, _rail(index) - 3 - lift * 5),
    point(_boxWidth - 8, _folderHeight, _rail(index) + _tabDepth - lift * 5),
  );
}

class _FileBoxPainter extends CustomPainter {
  const _FileBoxPainter(this.view, this.hovered, this.lift, this.selected);

  final _BoxView view;
  final int? hovered;
  final double lift;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    const wall = 152.0;
    final p = view.point;
    void face(Color color, List<Offset> vertices) {
      final path = Path()..addPolygon(vertices, true);
      canvas.drawPath(path, Paint()..color = color);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .69),
        width: math.min(size.width * .72, 540),
        height: 52,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .14 * (1 - view.focus))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    face(const Color(0xff47382a), [
      p(0, wall, 0),
      p(_boxWidth, wall, 0),
      p(_boxWidth, wall, _boxDepth),
      p(0, wall, _boxDepth),
    ]);
    for (var i = 0; i < _fileCount; i++) {
      if (i == selected) continue;
      final raised = i == hovered ? Curves.easeOut.transform(lift) : 0.0;
      final z = _rail(i) - raised * 5;
      final h = _folderHeight + raised * 25;
      final color = _fileColor(i);
      final x = _tabLeft(i);
      face(Color.lerp(color, const Color(0xff493f35), .48)!, [
        p(10, 14, z),
        p(_boxWidth - 10, 14, z),
        p(_boxWidth - 10, h, z),
        p(10, h, z),
      ]);
      face(Color.lerp(color, const Color(0xff493f35), .24)!, [
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
            text: _fileName(i),
            style: TextStyle(
              color: const Color(
                0xff2a211c,
              ).withValues(alpha: ((view.focus - .35) / .65).clamp(0.0, 1.0)),
              fontSize: (13 * view._scale).clamp(8.0, 15.0),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          p(x + _tabWidth / 2, h + 8, z + _tabDepth / 2) -
              Offset(label.width / 2, label.height / 2),
        );
        label.dispose();
      }
    }
    face(const Color(0xffb58253), [
      p(_boxWidth, 0, 0),
      p(_boxWidth, wall, 0),
      p(_boxWidth, wall, _boxDepth),
      p(_boxWidth, 0, _boxDepth),
    ]);
    face(const Color(0xffd4a475), [
      p(0, 0, _boxDepth),
      p(_boxWidth, 0, _boxDepth),
      p(_boxWidth, wall, _boxDepth),
      p(0, wall, _boxDepth),
    ]);
    final rim = Paint()
      ..color = const Color(0xffe5bc8d)
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

class _DiscoverReader extends StatelessWidget {
  const _DiscoverReader({
    required this.index,
    required this.source,
    required this.animation,
  });

  final int index;
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
            final folderWidth = math.min(size.width * .67, 600.0);
            final folderHeight = math.min(size.height * .42, folderWidth * .68);
            final center = size.center(Offset(0, size.height * .13));
            final openFolder = Rect.fromCenter(
              center: center,
              width: folderWidth,
              height: folderHeight,
            );
            final sheetStart = Rect.fromCenter(
              center: center.translate(0, -folderHeight * .1),
              width: folderWidth * .74,
              height: folderHeight * .77,
            );
            final sheetTop = sheetStart.shift(Offset(0, -folderHeight * .52));
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

                final extracted = phase(0, .38);
                final folder = Rect.lerp(source, openFolder, extracted)!.shift(
                  Offset(
                    0,
                    -math.sin(extracted * math.pi) * folderHeight * .38,
                  ),
                );
                final flap = phase(.33, .63);
                final rise = phase(.50, .73);
                final spread = phase(.69, 1);
                final folderOpacity = 1 - phase(.73, .90);
                final liftedSheet = Rect.lerp(sheetStart, sheetTop, rise)!;
                final opened = time == 1;
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
                            color: Color.lerp(color, Colors.black, .18)!,
                            back: true,
                          ),
                        ),
                      ),
                    if (rise > 0)
                      for (final (label, target) in [
                        ('Text', left),
                        ('Video', right),
                      ])
                        Positioned.fromRect(
                          rect: Rect.lerp(
                            liftedSheet.shift(
                              Offset(label == 'Text' ? -4 : 4, 0),
                            ),
                            target,
                            spread,
                          )!,
                          child: ColoredBox(
                            key: ValueKey('discover-$label-pane'),
                            color: label == 'Text'
                                ? Colors.white
                                : const Color(0xfff5f5f5),
                            child: opened
                                ? Semantics(
                                    container: true,
                                    label: label,
                                    child: label == 'Text'
                                        ? const SingleChildScrollView(
                                            child: SizedBox(
                                              width: double.infinity,
                                            ),
                                          )
                                        : const SizedBox.expand(),
                                  )
                                : null,
                          ),
                        ),
                    if (folderOpacity > 0)
                      Positioned.fromRect(
                        rect: folder,
                        child: Opacity(
                          opacity: folderOpacity,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, .0014)
                              ..rotateX(flap * 1.87),
                            child: _ReaderFolderFace(color: color),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SafeArea(
                        minimum: const EdgeInsets.all(12),
                        child: IconButton.filledTonal(
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
  const _ReaderFolderFace({required this.color, this.back = false});

  final Color color;
  final bool back;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        if (back)
          Positioned(
            left: constraints.maxWidth * .055,
            top: 0,
            width: constraints.maxWidth * .26,
            height: constraints.maxHeight * .25,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
            ),
          ),
        Positioned.fill(
          top: constraints.maxHeight * (back ? .12 : .18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
