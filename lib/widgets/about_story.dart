import 'package:flutter/material.dart';
import '../models/about_story_content.dart';
import 'site_copy_text.dart';
import 'site_parallax_image.dart';
import 'marketing_motion.dart';

const _ink = Color(0xFF173A27);

/// Public story sections share the page's real scroll position and editor slots.
class AboutStory extends StatelessWidget {
  const AboutStory({super.key, required this.controller, this.team = false});
  final ScrollController controller;
  final bool team;
  Widget _text(String id, {double size = 16, Color color = _ink}) =>
      SiteCopyText(
        'about.story.$id',
        aboutStoryCopy['about.story.$id']!,
        style: TextStyle(
          fontSize: size,
          height: size > 30 ? 1.08 : 1.65,
          letterSpacing: size > 30 ? -size * .035 : 0,
          color: color,
        ),
      );
  Widget _panel(Widget child, Color color, bool narrow) => Container(
    color: color,
    padding: EdgeInsets.symmetric(
      horizontal: narrow ? 24 : 64,
      vertical: narrow ? 64 : 104,
    ),
    child: Center(
      child: MarketingReveal(
        controller: controller,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: child,
        ),
      ),
    ),
  );
  Widget _photo(String key, String asset, double height, {Widget? child}) =>
      SiteParallaxImage(
        controller: controller,
        contentKey: key,
        asset: asset,
        maxTravel: 130,
        scrollFactor: .42,
        child: SizedBox(height: height, width: double.infinity, child: child),
      );
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 800;
    if (team)
      return _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text('team.eyebrow', size: 12),
            const SizedBox(height: 24),
            _text('team.title', size: narrow ? 40 : 64),
            const SizedBox(height: 24),
            _text('team.body', size: 18),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: 24,
                runSpacing: 40,
                children: [
                  for (var i = 0; i < 3; i++)
                    SizedBox(
                      width: narrow ? box.maxWidth : (box.maxWidth - 48) / 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _photo(
                              'image.about.team.$i',
                              'assets/images/pact-team-$i.png',
                              narrow ? 340 : 380,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _text('team.$i.name', size: 25),
                          const SizedBox(height: 6),
                          _text('team.$i.role', size: 14),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const Color(0xFFBDA3DD),
        narrow,
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarketingFilm(
          key: const Key('about-river-film'),
          controller: controller,
          contentKey: 'image.about.watershed',
          imageAsset: 'assets/images/pact-watershed.jpg',
          videoAsset: 'assets/product_tours/pact-river.mp4',
          height: narrow ? 480 : 660,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x10000000), Color(0xB8002019)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              narrow ? 24 : 64,
              64,
              narrow ? 24 : 64,
              90,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _text('film.label', size: 12, color: Colors.white),
                const SizedBox(height: 20),
                _text(
                  'film.title',
                  size: narrow ? 40 : 66,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text('purpose.eyebrow', size: 12),
              const SizedBox(height: 30),
              _text('purpose.title', size: narrow ? 42 : 72),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text('purpose.body', size: 20),
                      const SizedBox(height: 28),
                      _text('purpose.note', size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Color(0xFFA7C975),
          narrow,
        ),
        MarketingReveal(
          controller: controller,
          child: _photo(
            'image.about.workshop',
            'assets/images/pact-workshop.jpg',
            narrow ? 340 : 480,
          ),
        ),
        MarketingFilm(
          controller: controller,
          contentKey: 'image.about.collaboration',
          imageAsset: 'assets/images/pact-collaboration.jpg',
          videoAsset: 'assets/product_tours/pact-collaboration.mp4',
          height: narrow ? 360 : 500,
          child: Container(
            color: const Color(0x66072539),
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.fromLTRB(narrow ? 24 : 64, 24, 24, 90),
            child: SiteCopyText(
              'marketing.media.collaboration.title',
              marketingMotionCopy['marketing.media.collaboration.title']!,
              style: TextStyle(color: Colors.white, fontSize: narrow ? 42 : 72),
            ),
          ),
        ),
        _panel(
          LayoutBuilder(
            builder: (context, box) {
              final words = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text('pledge.eyebrow', size: 12, color: Colors.white),
                  const SizedBox(height: 24),
                  _text(
                    'pledge.amount',
                    size: narrow ? 86 : 120,
                    color: const Color(0xFF8DE3F0),
                  ),
                  _text(
                    'pledge.title',
                    size: narrow ? 30 : 38,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 26),
                  _text('pledge.body', size: 16, color: Colors.white),
                  const SizedBox(height: 24),
                  _text(
                    'pledge.note',
                    size: 13,
                    color: const Color(0xFFC4EAF1),
                  ),
                ],
              );
              final photo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(120),
                    child: _photo(
                      'image.about.river',
                      'assets/images/pact-river.jpg',
                      narrow ? 560 : 820,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _text(
                    'photo.credit',
                    size: 11,
                    color: const Color(0xFFC4EAF1),
                  ),
                ],
              );
              return narrow
                  ? Column(children: [words, const SizedBox(height: 40), photo])
                  : Row(
                      children: [
                        Expanded(flex: 4, child: words),
                        const SizedBox(width: 48),
                        Expanded(flex: 7, child: photo),
                      ],
                    );
            },
          ),
          const Color(0xFF155774),
          narrow,
        ),
      ],
    );
  }
}
