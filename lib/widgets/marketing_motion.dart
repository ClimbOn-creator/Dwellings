export '../models/marketing_motion_content.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/site_content_service.dart';
import 'site_copy_text.dart';
import 'site_parallax_image.dart';
import 'ambient_video.dart';

/// A clearly visible entrance, replayed when a section re-enters the viewport.
class MarketingReveal extends StatefulWidget {
  const MarketingReveal({
    super.key,
    required this.controller,
    required this.child,
  });
  final ScrollController controller;
  final Widget child;
  @override
  State<MarketingReveal> createState() => _MarketingRevealState();
}

class _MarketingRevealState extends State<MarketingReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  bool _visible = false, _scheduled = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_schedule);
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant MarketingReveal old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_schedule);
      widget.controller.addListener(_schedule);
    }
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final still =
          MediaQuery.disableAnimationsOf(context) ||
          SiteContentService.editing.value;
      if (still) {
        _animation.value = 1;
        return;
      }
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return;
      final top = box.localToGlobal(Offset.zero).dy;
      final visible =
          top < MediaQuery.sizeOf(context).height * .98 &&
          top + box.size.height > 70;
      if (visible && !_visible) _animation.forward(from: 0);
      if (!visible && _visible) _animation.value = 0;
      _visible = visible;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_schedule);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) => AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = editing || MediaQuery.disableAnimationsOf(context)
            ? 1.0
            : Curves.easeOutCubic.transform(_animation.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 64 * (1 - value)),
            child: child,
          ),
        );
      },
    ),
  );
}

class MarketingFilm extends StatefulWidget {
  const MarketingFilm({
    super.key,
    required this.controller,
    required this.contentKey,
    required this.imageAsset,
    required this.videoAsset,
    required this.height,
    this.child,
  });
  final ScrollController controller;
  final String contentKey, imageAsset, videoAsset;
  final double height;
  final Widget? child;
  @override
  State<MarketingFilm> createState() => _MarketingFilmState();
}

class _MarketingFilmState extends State<MarketingFilm> {
  bool _paused = false;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: Stack(
      children: [
        Positioned.fill(
          child: SiteParallaxImage(
            controller: widget.controller,
            contentKey: widget.contentKey,
            asset: widget.imageAsset,
            maxTravel: 130,
            scrollFactor: .42,
            movingBackground: AmbientVideo(
              url: 'assets/${widget.videoAsset}',
              poster: 'assets/${widget.imageAsset}',
              paused: _paused,
            ),
            child: SizedBox.expand(child: widget.child),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: SiteContentService.revision,
          builder: (context, _, _) => ValueListenableBuilder<bool>(
            valueListenable: SiteContentService.editing,
            builder: (context, editing, _) =>
                editing ||
                    MediaQuery.disableAnimationsOf(context) ||
                    SiteContentService.published(widget.contentKey) != null
                ? const SizedBox.shrink()
                : Positioned(
                    bottom: 18,
                    right: 18,
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _paused = !_paused),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xDD142916),
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        _paused ? Icons.play_arrow : Icons.pause,
                        size: 18,
                      ),
                      label: SiteCopyText(
                        _paused
                            ? 'marketing.motion.play'
                            : 'marketing.motion.pause',
                        _paused ? 'Play motion' : 'Pause motion',
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

/// An explicit per-device choice can enable motion even with reduced-motion OS settings.
final marketingMotionPreference = ValueNotifier<bool?>(null);

class MarketingMotionScope extends StatefulWidget {
  const MarketingMotionScope({super.key, required this.child});
  final Widget child;
  @override
  State<MarketingMotionScope> createState() => _MarketingMotionScopeState();
}

class _MarketingMotionScopeState extends State<MarketingMotionScope> {
  @override
  void initState() {
    super.initState();
    if (marketingMotionPreference.value == null) {
      SharedPreferences.getInstance().then((prefs) {
        if (mounted && marketingMotionPreference.value == null) {
          marketingMotionPreference.value = prefs.getBool(
            'pact.marketingMotion',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool?>(
    valueListenable: marketingMotionPreference,
    builder: (context, enabled, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: enabled == null
            ? MediaQuery.disableAnimationsOf(context)
            : !enabled,
      ),
      child: child!,
    ),
    child: widget.child,
  );
}

class MarketingMotionToggle extends StatelessWidget {
  const MarketingMotionToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final enabled = !MediaQuery.disableAnimationsOf(context);
    return OutlinedButton.icon(
      key: const Key('marketing-page-motion'),
      onPressed: () async {
        marketingMotionPreference.value = !enabled;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pact.marketingMotion', !enabled);
      },
      icon: Icon(
        enabled ? Icons.pause_circle_outline : Icons.play_circle_outline,
        size: 18,
      ),
      label: SiteCopyText(
        enabled
            ? 'marketing.motion.page.pause'
            : 'marketing.motion.page.enable',
        enabled ? 'Pause page motion' : 'Enable page motion',
      ),
    );
  }
}
