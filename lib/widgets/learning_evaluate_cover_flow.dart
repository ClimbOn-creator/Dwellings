import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/transaction_learning.dart';
import 'site_copy_text.dart';
import 'site_image.dart';
import 'transaction_room_panel.dart';

final _evaluationFiles = [
  for (final id in [
    'deal-brief',
    'nda-brief',
    'request-list',
    'earnings',
    'working-capital',
    'risk-log',
    'funding',
  ])
    transactionLessons.firstWhere((lesson) => lesson.id == id),
];

const _fileColors = [
  Color(0xFFD9C5A5),
  Color(0xFFB2C4BD),
  Color(0xFFB8C6D9),
  Color(0xFFD5B1A3),
  Color(0xFFDCCA96),
  Color(0xFFC4B7D0),
  Color(0xFFAFCBC6),
];

class LearningEvaluateCoverFlow extends StatefulWidget {
  const LearningEvaluateCoverFlow({super.key, required this.onOpenFile});

  final ValueChanged<String> onOpenFile;

  @override
  State<LearningEvaluateCoverFlow> createState() =>
      _LearningEvaluateCoverFlowState();
}

class _LearningEvaluateCoverFlowState extends State<LearningEvaluateCoverFlow>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(vsync: this);
  Timer? _wheelEnd;

  @override
  void dispose() {
    _wheelEnd?.cancel();
    _position.dispose();
    super.dispose();
  }

  double _relative(int index) {
    final count = _evaluationFiles.length;
    return (index - _position.value + count / 2) % count - count / 2;
  }

  void _settle(double target) {
    _wheelEnd?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = target;
      return;
    }
    _position.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _step(int direction) =>
      _settle((_position.value.round() + direction).toDouble());

  void _scroll(PointerSignalEvent signal, double stride) {
    if (signal is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(signal, (_) {
      _wheelEnd?.cancel();
      final delta = signal.scrollDelta;
      final movement = delta.dx.abs() > delta.dy.abs() ? delta.dx : delta.dy;
      _position.value += movement / stride;
      _wheelEnd = Timer(const Duration(milliseconds: 140), () {
        _settle(_position.value.roundToDouble());
      });
    });
  }

  void _select(int index) {
    final relative = _relative(index);
    if (relative.abs() > .05) {
      _settle((_position.value + relative).roundToDouble());
    } else {
      widget.onOpenFile(_evaluationFiles[index].id);
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
    },
    child: Focus(
      autofocus: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            const SiteCopyText(
              'learning.evaluate.files.title',
              'Evaluation files',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: learningInk,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth;
                final compact = width < 620;
                final stride = (width * .23).clamp(72.0, 166.0);
                final cardWidth = (width * .30).clamp(88.0, 228.0);
                final height = compact ? 264.0 : 398.0;
                return Listener(
                  onPointerSignal: (event) => _scroll(event, stride),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      _wheelEnd?.cancel();
                      _position.stop();
                    },
                    onHorizontalDragUpdate: (event) =>
                        _position.value -= event.delta.dx / stride,
                    onHorizontalDragEnd: (event) {
                      final velocity = event.primaryVelocity ?? 0;
                      final glide = (-velocity / (stride * 7)).clamp(-1.6, 1.6);
                      _settle((_position.value + glide).roundToDouble());
                    },
                    onHorizontalDragCancel: () =>
                        _settle(_position.value.roundToDouble()),
                    child: SizedBox(
                      key: const Key('evaluation-cover-flow'),
                      width: width,
                      height: height,
                      child: AnimatedBuilder(
                        animation: _position,
                        builder: (context, _) =>
                            _stage(width, height, cardWidth, compact),
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _position,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    tooltip: 'Previous file',
                    onPressed: () => _step(-1),
                    icon: const Icon(Icons.arrow_back, size: 19),
                  ),
                  SizedBox(
                    width: 74,
                    child: Text(
                      '${_position.value.round() % _evaluationFiles.length + 1} / ${_evaluationFiles.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: learningMuted),
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Next file',
                    onPressed: () => _step(1),
                    icon: const Icon(Icons.arrow_forward, size: 19),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _stage(double width, double height, double cardWidth, bool compact) {
    const cameraAngle = 35 * math.pi / 180;
    final radius = width * .42;
    final spread = compact ? .49 : .44;
    final files = [
      for (var i = 0; i < _evaluationFiles.length; i++)
        (index: i, relative: _relative(i)),
    ]..sort((a, b) => b.relative.abs().compareTo(a.relative.abs()));

    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            left: width * .08,
            right: width * .08,
            bottom: compact ? 35 : 33,
            height: height * .34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.elliptical(900, 180),
                ),
                color: const Color(0xFFF7F6F3),
                border: Border.all(color: const Color(0xFFECEAE5)),
              ),
            ),
          ),
          for (final file in files)
            if (file.relative.abs() < (compact ? 2.55 : 3.45))
              _positionedFile(
                file.index,
                file.relative,
                width,
                height,
                cardWidth,
                radius,
                spread,
                cameraAngle,
                compact,
              ),
        ],
      ),
    );
  }

  Widget _positionedFile(
    int index,
    double relative,
    double width,
    double height,
    double cardWidth,
    double radius,
    double spread,
    double cameraAngle,
    bool compact,
  ) {
    final angle = relative * spread;
    final depth = (1 - math.cos(angle));
    final scale = 1 - depth * .30;
    final size = cardWidth * scale;
    final left = width / 2 + math.sin(angle) * radius - size / 2;
    final rise = math.min(radius, 228.0) * depth * math.sin(cameraAngle);
    final fade = (((compact ? 2.55 : 3.45) - relative.abs()) / .45).clamp(
      0.0,
      1.0,
    );
    return Positioned(
      key: ValueKey('evaluate-file-${_evaluationFiles[index].id}'),
      left: left,
      width: size,
      top: height * .72 - size * 1.02 - rise,
      child: IgnorePointer(
        ignoring: fade < .3,
        child: Opacity(
          opacity: fade,
          child: _FileCover(
            lesson: _evaluationFiles[index],
            color: _fileColors[index],
            turn: angle,
            selected: relative.abs() < .5,
            onTap: () => _select(index),
          ),
        ),
      ),
    );
  }
}

class _FileCover extends StatefulWidget {
  const _FileCover({
    required this.lesson,
    required this.color,
    required this.turn,
    required this.selected,
    required this.onTap,
  });

  final TransactionLesson lesson;
  final Color color;
  final double turn;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FileCover> createState() => _FileCoverState();
}

class _FileCoverState extends State<_FileCover> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: Semantics(
      selected: widget.selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (value) => setState(() => _focus = value),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedSlide(
            offset: _hover || _focus ? const Offset(0, -.07) : Offset.zero,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .0017)
                    ..rotateX(-.12)
                    ..rotateY(-widget.turn * .8),
                  child: AspectRatio(
                    aspectRatio: 1.07,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 10,
                          width: 44,
                          height: 18,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          top: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: widget.color,
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1C000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SiteImage(
                                  contentKey:
                                      'image.transaction.${widget.lesson.id}.preview',
                                  original: Image.asset(
                                    widget.lesson.previewAsset,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SiteCopyText(
                  'transaction.${widget.lesson.id}.title',
                  widget.lesson.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.selected ? learningInk : learningMuted,
                    fontSize: widget.selected ? 14 : 12,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
