import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/site_content_service.dart';

/// A shared preference, but distinct visual palettes for questions and identity.
class PersonalMotion extends StatefulWidget {
  const PersonalMotion({
    super.key,
    this.profile = false,
    this.chapter = 0,
    required this.builder,
  });
  final bool profile;
  final int chapter;
  final Widget Function(BuildContext, ScrollController, Widget) builder;
  @override
  State<PersonalMotion> createState() => _PersonalMotionState();
}

class _PersonalMotionState extends State<PersonalMotion>
    with SingleTickerProviderStateMixin {
  final scroll = ScrollController();
  late final entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  bool? choice;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted && choice == null)
        setState(() => choice = prefs.getBool('affinity.landing.motion'));
    });
  }

  @override
  void dispose() {
    scroll.dispose();
    entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) {
      final enabled =
          (choice ?? !MediaQuery.disableAnimationsOf(context)) && !editing;
      final toggle = IconButton(
        tooltip: enabled ? 'Pause motion' : 'Enable motion',
        icon: Icon(
          enabled ? Icons.pause_circle_outline : Icons.play_circle_outline,
        ),
        onPressed: () async {
          setState(() => choice = !enabled);
          if (!enabled) entrance.forward(from: 0);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('affinity.landing.motion', !enabled);
        },
      );
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: !enabled),
        child: Builder(
          builder: (context) => AnimatedBuilder(
            animation: Listenable.merge([scroll, entrance]),
            child: widget.builder(context, scroll, toggle),
            builder: (context, child) {
              final p = enabled
                  ? entrance.value +
                        (scroll.hasClients ? scroll.offset / 1000 : 0)
                  : 1.0;
              final palettes = widget.profile
                  ? const [
                      Color(0xFFE9DDEB),
                      Color(0xFFF5EFE8),
                      Color(0xFFDDE7ED),
                    ]
                  : [
                      const Color(0xFFD7EAE4),
                      const Color(0xFFF5F2E9),
                      Color.lerp(
                        const Color(0xFFDCE6F4),
                        const Color(0xFFE5DDEE),
                        widget.chapter / 3,
                      )!,
                    ];
              return AnimatedContainer(
                duration: enabled
                    ? const Duration(milliseconds: 650)
                    : Duration.zero,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1, -1 + .3 * math.sin(p)),
                    end: Alignment(1, 1),
                    colors: palettes,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _OrbitPainter(p, widget.profile),
                        ),
                      ),
                    ),
                    child!,
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.progress, this.profile);
  final double progress;
  final bool profile;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = (profile ? const Color(0xFF765A87) : const Color(0xFF397369))
          .withValues(alpha: .13);
    final center = Offset(size.width * .87, 190 + math.sin(progress) * 48);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, 100 + i * 65 + progress * 9, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.progress != progress || old.profile != profile;
}
