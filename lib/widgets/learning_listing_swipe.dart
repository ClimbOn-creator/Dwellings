import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/learning_creative_content.dart';
import 'learning_activity_ui.dart';

class LearningListingSwipe extends StatefulWidget {
  const LearningListingSwipe({super.key});
  @override
  State<LearningListingSwipe> createState() => _LearningListingSwipeState();
}

class _LearningListingSwipeState extends State<LearningListingSwipe> {
  int _index = 0;
  final _choices = <bool>[];
  double _drag = 0;
  final _topKey = GlobalKey();

  bool get _complete => _index == creativeListings.length;
  bool get _revealed => !_complete && _choices.length > _index;

  void _vote(bool green) {
    if (_complete || _revealed) return;
    setState(() {
      _choices.add(green);
      _drag = 0;
    });
    _showCard();
  }

  void _next() {
    if (!_revealed) return;
    setState(() {
      _index++;
      _drag = 0;
    });
    _showCard();
  }

  void _showCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _topKey.currentContext == null) return;
      Scrollable.ensureVisible(
        _topKey.currentContext!,
        alignment: .06,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _vote(false),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () => _vote(true),
    },
    child: Focus(
      autofocus: true,
      child: Column(
        key: _topKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _complete
            ? [_summary()]
            : [
                Row(
                  children: [
                    Expanded(
                      child: creativeValue(
                        'search.counter',
                        '${_index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: activityForest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (var i = 0; i < creativeListings.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          width: 18,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i < _choices.length
                                ? activityForest
                                : const Color(0xFFD9DDCF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  key: const ValueKey('listing-swipe-card'),
                  onHorizontalDragUpdate: _revealed
                      ? null
                      : (details) => setState(() => _drag += details.delta.dx),
                  onHorizontalDragEnd: _revealed
                      ? null
                      : (details) {
                          if (_drag.abs() > 55 ||
                              details.velocity.pixelsPerSecond.dx.abs() > 450) {
                            _vote(
                              _drag == 0
                                  ? details.velocity.pixelsPerSecond.dx > 0
                                  : _drag > 0,
                            );
                          } else {
                            setState(() => _drag = 0);
                          }
                        },
                  onHorizontalDragCancel: () => setState(() => _drag = 0),
                  child: Transform.translate(
                    offset: Offset(_drag.clamp(-100, 100), 0),
                    child: Transform.rotate(
                      angle: _drag.clamp(-100, 100) / 1500,
                      child: Stack(
                        children: [
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 430),
                            transitionBuilder: (child, animation) =>
                                AnimatedBuilder(
                                  animation: animation,
                                  child: child,
                                  builder: (context, child) => Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, .001)
                                      ..rotateY(
                                        (1 - animation.value) * math.pi / 2,
                                      ),
                                    child: child,
                                  ),
                                ),
                            child: _revealed ? _back() : _front(),
                          ),
                          if (_drag.abs() > 10)
                            Positioned(
                              top: 24,
                              left: 24,
                              right: 24,
                              child: IgnorePointer(
                                child: Align(
                                  alignment: _drag > 0
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _drag > 0
                                          ? activityForest
                                          : activityRust,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: creativeCopy(
                                      _drag > 0 ? 'search.green' : 'search.red',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
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
                ),
                const SizedBox(height: 20),
                if (!_revealed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('listing-red'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: activityRust,
                            padding: const EdgeInsets.symmetric(vertical: 19),
                          ),
                          onPressed: () => _vote(false),
                          icon: const Icon(Icons.flag_outlined, size: 20),
                          label: creativeCopy(
                            'search.red',
                            style: const TextStyle(
                              color: activityRust,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('listing-green'),
                          style: FilledButton.styleFrom(
                            backgroundColor: activityForest,
                            padding: const EdgeInsets.symmetric(vertical: 19),
                          ),
                          onPressed: () => _vote(true),
                          icon: const Icon(Icons.flag_outlined, size: 20),
                          label: creativeCopy(
                            'search.green',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  creativeCopy(
                    'search.instructions',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF646B62),
                    ),
                  ),
                ] else
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: const ValueKey('listing-next'),
                      style: FilledButton.styleFrom(
                        backgroundColor: activityForest,
                        padding: const EdgeInsets.all(18),
                      ),
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: creativeCopy(
                        _index == 4 ? 'search.finish' : 'search.next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
      ),
    ),
  );

  Widget _front() {
    final id = creativeListings[_index].id;
    final color = const [
      Color(0xFFD5DCC6),
      Color(0xFFD5E0E7),
      Color(0xFFE9D6BC),
      Color(0xFFD3DFD4),
      Color(0xFFE1D7BC),
    ][_index];
    return Container(
      key: ValueKey('listing-front-$id'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9DCCF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 185,
            child: ColoredBox(
              color: color,
              child: CustomPaint(painter: _ShopfrontPainter(_index)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                creativeCopy(
                  'search.fictional',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A7164),
                  ),
                ),
                const SizedBox(height: 10),
                creativeCopy(
                  'search.$id.title',
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                creativeCopy(
                  'search.$id.category',
                  style: const TextStyle(fontSize: 14, color: activityForest),
                ),
                const SizedBox(height: 24),
                creativeCopy(
                  'search.$id.pitch',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.65,
                    color: activityInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _back() {
    final item = creativeListings[_index];
    final matched = _choices[_index] == item.green;
    return Container(
      key: ValueKey('listing-back-${item.id}'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: activityCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDD5C5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            matched ? Icons.visibility_outlined : Icons.lightbulb_outline,
            color: activityForest,
            size: 38,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                color: item.green ? activityForest : activityRust,
                size: 18,
              ),
              const SizedBox(width: 8),
              creativeCopy(
                item.green ? 'search.green' : 'search.red',
                style: TextStyle(
                  color: item.green ? activityForest : activityRust,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          creativeCopy(
            matched ? 'search.feedback.match' : 'search.feedback.missed',
            style: const TextStyle(
              fontSize: 25,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          creativeCopy(
            'search.${item.id}.title',
            style: const TextStyle(
              fontSize: 16,
              color: activityForest,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          creativeCopy('search.${item.id}.clue'),
          const SizedBox(height: 28),
          creativeCopy(
            'search.feedback.question',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: activityRust,
            ),
          ),
          const SizedBox(height: 10),
          creativeCopy(
            'search.${item.id}.question',
            style: const TextStyle(
              fontSize: 20,
              height: 1.5,
              color: activityInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final matches = List.generate(
      creativeListings.length,
      (i) => _choices[i] == creativeListings[i].green,
    ).where((match) => match).length;
    return Column(
      key: const ValueKey('listing-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: activityForest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              creativeValue(
                'search.score',
                '$matches',
                style: const TextStyle(
                  color: Color(0xFFD9E6CF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              creativeCopy(
                'search.complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              creativeCopy(
                'search.summary',
                style: activityBody.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < creativeListings.length; i++)
          ExpansionTile(
            leading: Icon(
              _choices[i] == creativeListings[i].green
                  ? Icons.visibility_outlined
                  : Icons.lightbulb_outline,
              color: activityForest,
            ),
            title: creativeCopy(
              'search.${creativeListings[i].id}.title',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              creativeCopy('search.${creativeListings[i].id}.clue'),
              const SizedBox(height: 12),
              creativeCopy('search.${creativeListings[i].id}.question'),
            ],
          ),
        const SizedBox(height: 20),
        OutlinedButton(
          key: const ValueKey('listing-restart'),
          onPressed: () {
            setState(() {
              _index = 0;
              _choices.clear();
              _drag = 0;
            });
            _showCard();
          },
          child: creativeCopy('search.restart'),
        ),
      ],
    );
  }
}

class _ShopfrontPainter extends CustomPainter {
  const _ShopfrontPainter(this.index);
  final int index;
  @override
  void paint(Canvas c, Size size) {
    final paint = Paint();
    final left = size.width * .2;
    final width = size.width * .6;
    final top = size.height * .2;
    final height = size.height * .67;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 12, top + 8, width + 24, height + 9),
        const Radius.circular(7),
      ),
      paint..color = const Color(0x16000000),
    );
    c.drawRect(
      Rect.fromLTWH(left, top, width, height),
      paint..color = const Color(0xFFF7F1DF),
    );
    c.drawRect(
      Rect.fromLTWH(left - 8, top, width + 16, 26),
      paint..color = activityForest,
    );
    c.drawRect(
      Rect.fromLTWH(left + width * .13, top + 43, width * .42, height - 58),
      paint..color = const Color(0xFFA6BFBD),
    );
    c.drawRect(
      Rect.fromLTWH(left + width * .65, top + 43, width * .23, height - 43),
      paint..color = const Color(0xFF72918A),
    );
    c.drawCircle(
      Offset(left + width * .8, top + height * .76),
      2.5,
      paint..color = const Color(0xFFF3D7A0),
    );
    if (index == 0) {
      for (var i = 0; i < 2; i++) {
        final x = left + width * (.22 + i * .2);
        c.drawCircle(
          Offset(x, top + height * .65),
          13,
          paint..color = const Color(0xFFF7F5ED),
        );
        c.drawCircle(
          Offset(x, top + height * .65),
          9,
          paint..color = const Color(0xFF557A79),
        );
      }
    }
    c.drawRect(
      Rect.fromLTWH(left - 20, top + height, width + 40, 6),
      paint..color = const Color(0xFF829581),
    );
    c.drawOval(
      Rect.fromLTWH(size.width * .08, size.height * .7, 28, 30),
      paint..color = const Color(0xFF7D946E),
    );
    c.drawRect(
      Rect.fromLTWH(size.width * .08 + 11, size.height * .83, 5, 18),
      paint..color = const Color(0xFF8D7E65),
    );
  }

  @override
  bool shouldRepaint(_ShopfrontPainter oldDelegate) =>
      oldDelegate.index != index;
}
