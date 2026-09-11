import 'package:flutter/material.dart';
import '../services/site_content_service.dart';
import 'site_copy_text.dart';
import 'site_image.dart';
import 'site_text.dart';

const _night = Color(0xFF101313);
const _ivory = Color(0xFFF4F3ED);

/// A scene occupies several viewport lengths while its stage stays in view.
/// Scrolling stays native: no wheel interception, snapping, or forced navigation.
class AffinityScrollScene extends StatelessWidget {
  const AffinityScrollScene({
    super.key,
    required this.controller,
    required this.startOffset,
    required this.screens,
    required this.builder,
    required this.fallback,
  });
  final ScrollController controller;
  final double startOffset, screens;
  final Widget Function(BuildContext, double, double) builder;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) {
      final size = MediaQuery.sizeOf(context);
      final still =
          editing ||
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.textScalerOf(context).scale(16) > 22 ||
          size.height < 600;
      if (still) return fallback;
      final height = size.height - 82;
      final distance = height * (screens - 1);
      return SizedBox(
        height: height * screens,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final local =
                  ((controller.hasClients ? controller.offset : 0) -
                          startOffset)
                      .clamp(0.0, distance);
              return Stack(
                children: [
                  Positioned(
                    top: local,
                    left: 0,
                    right: 0,
                    height: height,
                    child: builder(context, local / distance, height),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class AffinityCinemaHero extends StatefulWidget {
  const AffinityCinemaHero({
    super.key,
    required this.progress,
    required this.height,
    required this.onBuyer,
    required this.onMember,
  });
  final double progress, height;
  final VoidCallback onBuyer, onMember;
  @override
  State<AffinityCinemaHero> createState() => _AffinityCinemaHeroState();
}

class _AffinityCinemaHeroState extends State<AffinityCinemaHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 760;
    final p = widget.progress;
    final departure = (p / .56).clamp(0.0, 1.0);
    final arrival = ((p - .42) / .4).clamp(0.0, 1.0);
    return ColoredBox(
      color: _night,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _arrival,
          child: SiteImage(
            contentKey: 'image.acquisition_support_page.mbackground1',
            original: Image.asset(
              'assets/images/affinity-city-hero.jpg',
              fit: BoxFit.cover,
            ),
          ),
          builder: (context, photo) {
            final entrance = Curves.easeOutCubic.transform(_arrival.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                // An obvious camera push: photography and foreground type have
                // deliberately different trajectories and magnification.
                Transform.translate(
                  offset: Offset(-p * width * .07, p * 35),
                  child: Transform.scale(
                    scale: 1.12 + p * .58 + (1 - entrance) * .16,
                    child: RepaintBoundary(child: photo),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0x66101313),
                        Color.lerp(
                          const Color(0x66101313),
                          const Color(0xBB101313),
                          p,
                        )!,
                        const Color(0xF2101313),
                      ],
                    ),
                  ),
                ),
                // Architectural shutters open on arrival and separate further on scroll.
                IgnorePointer(
                  child: Row(
                    children: [
                      Container(
                        width: (1 - entrance) * width * .5,
                        color: _night,
                      ),
                      const Spacer(),
                      Container(
                        width: (1 - entrance) * width * .5,
                        color: _night,
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  ignoring: departure > .85,
                  child: Opacity(
                    opacity: (1 - departure) * entrance,
                    child: Transform.translate(
                      offset: Offset(0, 34 * (1 - entrance) - p * 210),
                      child: Transform.scale(
                        scale: 1 + p * .3,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            narrow ? 24 : 80,
                            narrow ? 48 : 62,
                            narrow ? 24 : 80,
                            90,
                          ),
                          child: _FitScene(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SiteCopyText(
                                  'home.eyebrow',
                                  'BUSINESS ACQUISITION, MADE NAVIGABLE',
                                  style: TextStyle(
                                    color: _ivory,
                                    fontSize: 12,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: narrow ? 600 : 1040,
                                  ),
                                  child: SiteCopyText(
                                    'home.title',
                                    'Don’t just find a business.\nKnow what you’re buying into.',
                                    style: TextStyle(
                                      fontSize: narrow
                                          ? 46
                                          : width < 1150
                                          ? 70
                                          : 92,
                                      height: 1.02,
                                      letterSpacing: narrow ? -1.8 : -3.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (!narrow)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 660,
                                    ),
                                    child: SiteCopyText(
                                      'home.intro',
                                      'Affinity helps aspiring buyers define the right target, prepare to transact, screen real opportunities, and build the professional team needed to close with confidence.',
                                      style: TextStyle(
                                        color: const Color(0xFFE2E5E3),
                                        fontSize: narrow ? 16 : 18,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 28),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  children: [
                                    _CinemaButton(
                                      'copy.acquisition_support_page.2',
                                      'I WANT TO BUY A BUSINESS',
                                      widget.onBuyer,
                                    ),
                                    _CinemaButton(
                                      'copy.acquisition_support_page.3',
                                      'I PROVIDE PROFESSIONAL SERVICES',
                                      widget.onMember,
                                      outline: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: arrival < .9,
                  child: Opacity(
                    opacity: arrival,
                    child: Transform.translate(
                      offset: Offset(
                        width * .13 * (1 - arrival),
                        widget.height * .24 * (1 - arrival),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: narrow ? 24 : 80,
                        ),
                        child: _FitScene(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SiteCopyText(
                                'home.cinema.eyebrow',
                                'FROM POSSIBILITY TO PERSPECTIVE',
                                style: TextStyle(
                                  color: _ivory,
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SiteCopyText(
                                'home.cinema.statement',
                                'A bigger future.\nA clearer view.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: narrow ? 60 : 112,
                                  height: .98,
                                  letterSpacing: -3,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 30),
                              const SizedBox(
                                width: 520,
                                child: SiteCopyText(
                                  'home.cinema.body',
                                  'Turn the ambition to own a business into a path you can act on. Define your target. Understand the opportunity. Bring the right people with you.',
                                  style: TextStyle(
                                    color: _ivory,
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: narrow ? 24 : 80,
                  right: narrow ? 24 : 80,
                  bottom: 25,
                  child: Row(
                    children: [
                      const Icon(Icons.south, size: 18, color: Colors.white),
                      const SizedBox(width: 12),
                      const SiteCopyText(
                        'home.cinema.scroll',
                        'SCROLL TO EXPLORE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: narrow ? 70 : 160,
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 2,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CinemaButton extends StatelessWidget {
  const _CinemaButton(this.id, this.label, this.onTap, {this.outline = false});
  final String id, label;
  final VoidCallback onTap;
  final bool outline;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: outline ? Colors.white : _night,
      backgroundColor: outline ? const Color(0x22101313) : _ivory,
      side: BorderSide(color: outline ? Colors.white54 : _ivory),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: const RoundedRectangleBorder(),
    ),
    iconAlignment: IconAlignment.end,
    icon: const Icon(Icons.arrow_outward, size: 18),
    label: SiteCopyText(
      id,
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: .5,
      ),
    ),
  );
}

class AffinityCinemaChapters extends StatelessWidget {
  const AffinityCinemaChapters({super.key, required this.progress});
  final double progress;
  static const chapters = [
    (
      'DEFINE',
      'Build a buyer-first acquisition Blueprint.',
      'Set the industries, geography, price range, role, return expectations, and hard limits that define a viable target.',
      'affinity-city-hero.jpg',
    ),
    (
      'PREPARE',
      'Know what must be true before you transact.',
      'Organize capital, reserves, documentation, operating credibility, and lender conversations into an honest readiness view.',
      'affinity-consulting.jpg',
    ),
    (
      'SCREEN',
      'Pressure-test the deal—not your hopes.',
      'Normalize earnings, account for owner pay and working capital, test debt, and expose missing evidence before an offer.',
      'affinity-deal-screen.jpg',
    ),
    (
      'CONNECT',
      'Bring in the right expertise at the right moment.',
      'Find member professionals whose services match the financing, legal, diligence, tax, risk, and transition work ahead.',
      'affinity-member-studio.jpg',
    ),
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final narrow = box.maxWidth < 760;
      final raw = progress * 3.75;
      final page =
          (raw.floor() +
                  Curves.easeInOutCubic.transform(
                    ((raw % 1 - .38) / .62).clamp(0.0, 1.0),
                  ))
              .clamp(0.0, 3.0);
      return ColoredBox(
        color: _night,
        child: ClipRect(
          child: Stack(
            children: [
              for (var i = 0; i < chapters.length; i++)
                if ((i - page).abs() < 1.1)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset((i - page) * box.maxWidth, 0),
                      child: ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.translate(
                              offset: Offset((page - i) * box.maxWidth * .2, 0),
                              child: Transform.scale(
                                scale: 1.5,
                                child: SiteImage(
                                  contentKey: 'image.home.cinema.chapter.$i',
                                  original: Image.asset(
                                    'assets/images/${chapters[i].$4}',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xF2101313),
                                    Color(0x77101313),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                narrow ? 24 : 80,
                                90,
                                narrow ? 24 : 80,
                                86,
                              ),
                              child: _FitScene(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '0${i + 1}',
                                      style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: narrow ? 80 : 140,
                                        height: 1,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SiteText(
                                      chapters[i].$1,
                                      contentKey:
                                          'copy.acquisition_support_page.m7',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 800,
                                      ),
                                      child: SiteText(
                                        chapters[i].$2,
                                        contentKey:
                                            'copy.acquisition_support_page.m8',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: narrow ? 38 : 66,
                                          height: 1.04,
                                          letterSpacing: -1.8,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 600,
                                      ),
                                      child: SiteText(
                                        chapters[i].$3,
                                        contentKey:
                                            'copy.acquisition_support_page.m9',
                                        style: TextStyle(
                                          color: const Color(0xFFDFE3E0),
                                          fontSize: narrow ? 17 : 20,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              Positioned(
                top: 30,
                left: narrow ? 24 : 80,
                right: 24,
                child: const SiteCopyText(
                  'copy.acquisition_support_page.m1',
                  'WHAT AFFINITY MOVES FORWARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: narrow ? 24 : 80,
                right: narrow ? 24 : 80,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: LinearProgressIndicator(
                            value: (page - i + 1).clamp(0, 1),
                            minHeight: 2,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    const Icon(Icons.south, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FitScene extends StatelessWidget {
  const _FitScene({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(width: box.maxWidth, child: child),
      ),
    ),
  );
}
