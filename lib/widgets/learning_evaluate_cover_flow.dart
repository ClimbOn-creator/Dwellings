import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/transaction_learning.dart';
import 'site_copy_text.dart';
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

  Future<void> _select(int index) async {
    final relative = _relative(index);
    if (relative.abs() > .05) {
      _settle((_position.value + relative).roundToDouble());
      return;
    }
    _wheelEnd?.cancel();
    final openGuide = await showDialog<bool>(
      context: context,
      builder: (_) => _EvaluationFolderOpening(
        lesson: _evaluationFiles[index],
        color: _fileColors[index],
      ),
    );
    if (mounted && openGuide == true) {
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
        padding: const EdgeInsets.only(top: 78, bottom: 20),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth;
                final compact = width < 620;
                final stride = (width * .23).clamp(72.0, 166.0);
                final cardWidth = (width * .34).clamp(104.0, 260.0);
                final height = compact ? 245.0 : 380.0;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  tooltip: 'Previous file',
                  onPressed: () => _step(-1),
                  icon: const Icon(Icons.arrow_back, size: 19),
                ),
                const SizedBox(width: 22),
                IconButton.outlined(
                  tooltip: 'Next file',
                  onPressed: () => _step(1),
                  icon: const Icon(Icons.arrow_forward, size: 19),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _stage(double width, double height, double cardWidth, bool compact) {
    final limit = compact ? 2.25 : 3.45;
    final spacing = (width - cardWidth * .72) / (compact ? 3.9 : 6);
    final files = [
      for (var i = 0; i < _evaluationFiles.length; i++)
        (index: i, relative: _relative(i)),
    ]..sort((a, b) => b.relative.abs().compareTo(a.relative.abs()));

    return ClipRect(
      child: Stack(
        children: [
          for (final file in files)
            if (file.relative.abs() < limit)
              Positioned(
                key: ValueKey(
                  'evaluate-file-${_evaluationFiles[file.index].id}',
                ),
                left: width / 2 + file.relative * spacing - cardWidth / 2,
                top: height - cardWidth / 1.07 - 66,
                width: cardWidth,
                child: Opacity(
                  opacity: ((limit - file.relative.abs()) / .45).clamp(
                    0.0,
                    1.0,
                  ),
                  child: _FileCover(
                    lesson: _evaluationFiles[file.index],
                    color: _fileColors[file.index],
                    turn: (file.relative * .19).clamp(-.55, .55),
                    labelWidth: spacing - 6,
                    selected: file.relative.abs() < .5,
                    onTap: () => _select(file.index),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _FileCover extends StatefulWidget {
  const _FileCover({
    required this.lesson,
    required this.color,
    required this.turn,
    required this.labelWidth,
    required this.selected,
    required this.onTap,
  });

  final TransactionLesson lesson;
  final Color color;
  final double turn, labelWidth;
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
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .0013)
                    ..rotateY(-widget.turn)
                    ..rotateX(-.53),
                  child: AspectRatio(
                    aspectRatio: 1.07,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 12,
                          width: 48,
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
                          child: _CoverSurface(color: widget.color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: widget.labelWidth,
                    child: SiteCopyText(
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

class _CoverSurface extends StatelessWidget {
  const _CoverSurface({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
  );
}

class _EvaluationFolderOpening extends StatelessWidget {
  const _EvaluationFolderOpening({required this.lesson, required this.color});

  final TransactionLesson lesson;
  final Color color;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .54).clamp(
              150.0,
              338.0,
            ),
            child: LayoutBuilder(
              builder: (context, box) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 720),
                curve: Curves.easeInOutCubic,
                builder: (context, progress, _) {
                  final height = box.maxHeight;
                  final slide = ((progress - .18) / .82).clamp(0.0, 1.0);
                  return Stack(
                    children: [
                      Positioned.fill(
                        top: height * .33,
                        child: _CoverSurface(color: color),
                      ),
                      Positioned(
                        key: const Key('evaluate-rising-sheet'),
                        left: 22,
                        right: 22,
                        top: height * (.39 - slide * .33),
                        bottom: height * (.05 + slide * .17),
                        child: Opacity(
                          opacity: (progress * 3).clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE4E4E4),
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 34, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SiteCopyText(
                                    'transaction.${lesson.id}.title',
                                    lesson.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  for (final width in [.88, .73, .81])
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: FractionallySizedBox(
                                        widthFactor: width,
                                        child: const SizedBox(
                                          height: 2,
                                          child: ColoredBox(
                                            color: Color(0xFFEAEAEA),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: height * .64,
                        child: Transform(
                          key: const Key('evaluate-opening-flap'),
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .001)
                            ..rotateX(progress * 1.23),
                          child: _CoverSurface(color: color),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 5,
                        child: IconButton.filledTonal(
                          tooltip: 'Close folder',
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: learningInk,
                          ),
                          icon: const Icon(Icons.close, size: 19),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open document guide'),
          ),
        ],
      ),
    ),
  );
}
