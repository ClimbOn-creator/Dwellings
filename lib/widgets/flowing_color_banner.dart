import 'site_inline_editor.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/site_content_service.dart';

/// A continuously drifting color field, confined to the profile cover.
class FlowingColorBanner extends StatefulWidget {
  const FlowingColorBanner({super.key});
  @override
  State<FlowingColorBanner> createState() => _FlowingColorBannerState();
}

class _FlowingColorBannerState extends State<FlowingColorBanner>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) {
      final enabled = !MediaQuery.disableAnimationsOf(context) && !editing;
      if (enabled && !controller.isAnimating) controller.repeat();
      if (!enabled && controller.isAnimating) controller.stop();
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) =>
              CustomPaint(painter: _ColorField(enabled ? controller.value : 0)),
        ),
      );
    },
  );
}

class _ColorField extends CustomPainter {
  const _ColorField(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF8F7FF));
    final t = phase * math.pi * 2;
    final fields = [
      (
        Alignment(-.55 + .23 * math.sin(t), .8 + .3 * math.cos(t)),
        const Color(0xFF7363FF),
        .68,
      ),
      (
        Alignment(.2 + .3 * math.cos(t), -.3 + .3 * math.sin(t)),
        const Color(0xFFBBA9FF),
        .8,
      ),
      (
        Alignment(.85 + .15 * math.sin(t), -.65 + .4 * math.cos(t)),
        const Color(0xFFFFA7EF),
        .7,
      ),
    ];
    for (final f in fields) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: f.$1,
            radius: math.max(
              1.0,
              size.width / math.max(size.height, 1) * f.$3 * .6,
            ),
            colors: [f.$2, f.$2.withValues(alpha: 0)],
            stops: const [.08, 1],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_ColorField old) => phase != old.phase;
}

/// Preserve uploaded covers while allowing a code-rendered default.
class EditableColorCover extends StatelessWidget {
  const EditableColorCover({
    super.key,
    required this.contentKey,
    required this.original,
    this.wash,
  });
  final String contentKey;
  final Widget original;
  final Color? wash;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: SiteContentService.revision,
    builder: (context, _, _) {
      final url = SiteContentService.published(contentKey);
      return SiteEditTarget(
        contentKey: contentKey,
        fallback: '',
        image: true,
        child: url == null
            ? original
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => original,
                  ),
                  if (wash != null) ColoredBox(color: wash!),
                ],
              ),
      );
    },
  );
}
