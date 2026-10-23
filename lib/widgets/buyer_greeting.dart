import 'package:flutter/material.dart';
import 'dashboard_ui.dart';

/// A horizontal reveal replays each time Home is opened, with stable layout.
class BuyerGreeting extends StatefulWidget {
  const BuyerGreeting({
    super.key,
    required this.greeting,
    required this.summary,
    this.showGreeting = true,
  });
  final String greeting, summary;
  final bool showGreeting;
  @override
  State<BuyerGreeting> createState() => _BuyerGreetingState();
}

class _BuyerGreetingState extends State<BuyerGreeting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      // The owner explicitly requests this animation on every dashboard visit.
      animationBehavior: AnimationBehavior.preserve,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant BuyerGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.greeting != widget.greeting) _reveal.forward(from: 0);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Widget _line(String text, double progress, TextStyle style, String key) =>
      Semantics(
        label: text,
        child: ExcludeSemantics(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ClipRect(
              key: ValueKey('$key-reveal'),
              clipper: _GreetingRevealClipper(progress),
              child: Text(text, key: ValueKey(key), style: style),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _reveal,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showGreeting)
          _line(
            widget.greeting,
            Curves.easeInOut.transform((_reveal.value / .8).clamp(0, 1)),
            const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
            'buyer-greeting-visible',
          ),
        if (widget.showGreeting) const SizedBox(height: 5),
        _line(
          widget.summary,
          Curves.easeInOut.transform(((_reveal.value - .2) / .8).clamp(0, 1)),
          const TextStyle(color: DashboardUi.muted),
          'buyer-summary-visible',
        ),
      ],
    ),
  );
}

class _GreetingRevealClipper extends CustomClipper<Rect> {
  const _GreetingRevealClipper(this.progress);
  final double progress;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);
  @override
  bool shouldReclip(_GreetingRevealClipper oldClipper) =>
      progress != oldClipper.progress;
}
