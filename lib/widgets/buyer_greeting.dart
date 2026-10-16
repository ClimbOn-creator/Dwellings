import 'package:flutter/material.dart';
import 'dashboard_ui.dart';

/// Replays when Home is opened, without shifting the surrounding dashboard.
class BuyerGreeting extends StatefulWidget {
  const BuyerGreeting({
    super.key,
    required this.greeting,
    required this.summary,
  });
  final String greeting, summary;
  @override
  State<BuyerGreeting> createState() => _BuyerGreetingState();
}

class _BuyerGreetingState extends State<BuyerGreeting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typing;
  int get _titleLength => widget.greeting.characters.length;
  int get _length => _titleLength + widget.summary.characters.length;
  @override
  void initState() {
    super.initState();
    _typing = AnimationController(vsync: this);
    _start();
  }

  void _start() {
    _typing.duration = Duration(milliseconds: _length * 24);
    _typing.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant BuyerGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.greeting != widget.greeting ||
        oldWidget.summary != widget.summary)
      _start();
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  Widget _line(String text, int count, TextStyle style, String key) =>
      Semantics(
        label: text,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, box) {
              final painter = TextPainter(
                text: TextSpan(
                  text: text,
                  style: DefaultTextStyle.of(context).style.merge(style),
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: box.maxWidth);
              final height = painter.height;
              painter.dispose();
              return SizedBox(
                height: height,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    text.characters
                        .take(count.clamp(0, text.characters.length))
                        .toString(),
                    key: ValueKey(key),
                    style: style,
                  ),
                ),
              );
            },
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _typing,
    builder: (context, _) {
      final count = MediaQuery.disableAnimationsOf(context)
          ? _length
          : (_typing.value * _length).floor();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(
            widget.greeting,
            count,
            const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
            'buyer-greeting-visible',
          ),
          const SizedBox(height: 5),
          _line(
            widget.summary,
            count - _titleLength,
            const TextStyle(color: DashboardUi.muted),
            'buyer-summary-visible',
          ),
        ],
      );
    },
  );
}
