import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/site_content_service.dart';
import 'site_copy_text.dart';
import 'site_inline_editor.dart';

const partnerPreviewNames = [
  'VEYRA',
  'MORROW ARC',
  'TERNFIELD',
  'ONDA VALE',
  'KIVO WORKS',
  'ASTER & OAK',
];

/// A seamless, constant-speed loop. Each emblem has the same optical canvas.
/// It runs only in view, and stays still while the owner edits the content.
class PartnerEmblemCarousel extends StatefulWidget {
  const PartnerEmblemCarousel({super.key, required this.controller});
  final ScrollController controller;
  @override
  State<PartnerEmblemCarousel> createState() => _PartnerEmblemCarouselState();
}

class _PartnerEmblemCarouselState extends State<PartnerEmblemCarousel>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 38),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _checkPending = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_queueVisibility);
    SiteContentService.editing.addListener(_queueVisibility);
    _queueVisibility();
  }

  void _queueVisibility() {
    if (_checkPending) return;
    _checkPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPending = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      var visible = false;
      if (box is RenderBox && box.hasSize && widget.controller.hasClients) {
        final position = widget.controller.position;
        final top = RenderAbstractViewport.of(
          box,
        ).getOffsetToReveal(box, 0).offset;
        visible =
            position.pixels < top + box.size.height &&
            position.pixels + position.viewportDimension > top;
      }
      if (visible && !SiteContentService.editing.value) {
        if (!_motion.isAnimating) _motion.repeat();
      } else {
        _motion.stop();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_queueVisibility);
    SiteContentService.editing.removeListener(_queueVisibility);
    _motion.dispose();
    super.dispose();
  }

  Widget _emblem(int index) => SizedBox(
    width: 220,
    height: 150,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: ValueListenableBuilder<int>(
            valueListenable: SiteContentService.revision,
            builder: (context, _, _) {
              final key = 'image.home.partner.$index';
              final published = SiteContentService.published(key);
              return SiteEditTarget(
                contentKey: key,
                fallback: '',
                image: true,
                child: published != null
                    ? Image.network(published, fit: BoxFit.contain)
                    : CustomPaint(painter: _EmblemPainter(index)),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SiteCopyText(
          'home.partners.name.$index',
          partnerPreviewNames[index],
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFF173A27),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('home-partner-carousel'),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const SiteCopyText(
            'home.partners.eyebrow',
            'ROOM FOR GOOD COMPANY',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Color(0xFF173A27),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 170,
            child: LayoutBuilder(
              builder: (context, box) {
                const period = 220.0 * 6;
                final copies = (box.maxWidth / period).ceil() + 1;
                return ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: period * copies,
                    maxWidth: period * copies,
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (_, child) => Transform.translate(
                        key: const Key('partner-carousel-track'),
                        offset: Offset(-_motion.value * period, 0),
                        child: child,
                      ),
                      child: Row(
                        children: [
                          for (var copy = 0; copy < copies; copy++)
                            for (var i = 0; i < 6; i++)
                              ExcludeSemantics(
                                excluding: copy > 0,
                                child: _emblem(i),
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const SiteCopyText(
            'home.partners.preview',
            'Fictional partner emblems · motion preview',
            style: TextStyle(fontSize: 12, color: Color(0xFF66736B)),
          ),
        ],
      ),
    ),
  );
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter(this.index);
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final paint = Paint()
      ..color = const Color(0xFF285C48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (index) {
      case 0:
        canvas.drawPath(
          Path()
            ..moveTo(8, 12)
            ..lineTo(32, 54)
            ..lineTo(56, 12),
          paint,
        );
        canvas.drawLine(const Offset(22, 12), const Offset(42, 12), paint);
      case 1:
        canvas.drawArc(
          const Rect.fromLTWH(7, 7, 50, 50),
          math.pi,
          math.pi,
          false,
          paint,
        );
        canvas.drawLine(const Offset(8, 48), const Offset(56, 48), paint);
        canvas.drawCircle(
          const Offset(32, 38),
          4,
          paint..style = PaintingStyle.fill,
        );
      case 2:
        for (final dx in [18.0, 32.0, 46.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(dx - 10, 43)
              ..lineTo(dx, 17)
              ..lineTo(dx + 10, 43),
            paint,
          );
        }
      case 3:
        for (final dy in [19.0, 32.0, 45.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(8, dy)
              ..cubicTo(24, dy - 16, 40, dy + 16, 56, dy),
            paint,
          );
        }
      case 4:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 8, 48, 48),
            const Radius.circular(12),
          ),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(24, 18)
            ..lineTo(24, 46)
            ..moveTo(44, 18)
            ..lineTo(27, 32)
            ..lineTo(44, 46),
          paint,
        );
      default:
        for (var i = 0; i < 8; i++) {
          canvas.save();
          canvas.translate(32, 32);
          canvas.rotate(i * math.pi / 4);
          canvas.drawLine(const Offset(0, 10), const Offset(0, 25), paint);
          canvas.restore();
        }
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) => oldDelegate.index != index;
}
