import 'package:flutter/material.dart';
import '../models/about_story_content.dart';
import 'site_copy_text.dart';
import 'site_parallax_image.dart';
import 'learning_media_player.dart';

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: child,
      ),
    ),
  );
  Widget _photo(String key, String asset, double height, {Widget? child}) =>
      SiteParallaxImage(
        controller: controller,
        contentKey: key,
        asset: asset,
        maxTravel: 80,
        child: SizedBox(height: height, width: double.infinity, child: child),
      );
  void _film(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: aboutStoryCopy['about.story.film.close'],
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Flexible(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: const LearningMediaPlayer(
                    url: 'assets/assets/product_tours/pact-river.mp4',
                    poster: 'assets/assets/images/pact-watershed.jpg',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _text('film.credit', size: 12),
            ],
          ),
        ),
      ),
    ),
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
        const Color(0xFFE9E3EF),
        narrow,
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _photo(
          'image.about.watershed',
          'assets/images/pact-watershed.jpg',
          narrow ? 440 : 620,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x10000000), Color(0xB8002019)],
              ),
            ),
            padding: EdgeInsets.all(narrow ? 24 : 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _text('film.label', size: 12, color: Colors.white),
                const SizedBox(height: 20),
                _text(
                  'film.title',
                  size: narrow ? 44 : 78,
                  color: Colors.white,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  key: const Key('about-river-film'),
                  onPressed: () => _film(context),
                  icon: const Icon(Icons.play_circle_outline),
                  label: _text('film.action', color: Colors.white),
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
          const Color(0xFFDCE5D0),
          narrow,
        ),
        _panel(
          LayoutBuilder(
            builder: (context, box) {
              final words = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text('pledge.eyebrow', size: 12),
                  const SizedBox(height: 24),
                  _text('pledge.amount', size: narrow ? 100 : 150),
                  _text('pledge.title', size: narrow ? 36 : 48),
                  const SizedBox(height: 26),
                  _text('pledge.body', size: 18),
                  const SizedBox(height: 24),
                  _text('pledge.note', size: 13),
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
                      narrow ? 420 : 640,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _text('photo.credit', size: 11),
                ],
              );
              return narrow
                  ? Column(children: [words, const SizedBox(height: 40), photo])
                  : Row(
                      children: [
                        Expanded(child: words),
                        const SizedBox(width: 90),
                        Expanded(child: photo),
                      ],
                    );
            },
          ),
          const Color(0xFFF4F1EB),
          narrow,
        ),
      ],
    );
  }
}
