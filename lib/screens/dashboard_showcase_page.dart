import '../services/site_content_service.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_showcase_content.dart';
import '../models/platform_side.dart';
import '../services/app_tunnel.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/learning_media_player.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/site_image.dart';
import '../widgets/site_parallax_image.dart';
import '../widgets/marketing_motion.dart';
import 'deal_rooms_page.dart';
import 'seller_dashboard_page.dart';
import 'member_deal_marketplace_page.dart';
import 'learning_dashboard_page.dart';

const _forest = Color(0xFF173A27);
const _paper = Color(0xFFBFD9DD);
const _roles = ['buyer', 'seller', 'member', 'learning'];
const _colors = [
  Color(0xFFA7C975),
  Color(0xFFE9AB87),
  Color(0xFFBBA0DC),
  Color(0xFF80BAD4),
];

/// Public product presentation; independent of account and workspace roles.
class DashboardShowcasePage extends StatefulWidget {
  const DashboardShowcasePage({super.key});
  @override
  State<DashboardShowcasePage> createState() => _DashboardShowcasePageState();
}

class _DashboardShowcasePageState extends State<DashboardShowcasePage> {
  int _preview = 0, _tour = 0;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  final _spaces = GlobalKey(), _tours = GlobalKey();
  bool get narrow => MediaQuery.sizeOf(context).width < 800;
  Widget _copy(
    String id, {
    double size = 16,
    Color color = _forest,
    FontWeight weight = FontWeight.w400,
  }) => SiteCopyText(
    'showcase.$id',
    dashboardShowcaseCopy['showcase.$id']!,
    style: TextStyle(
      fontSize: size,
      height: size > 30 ? 1.05 : 1.6,
      letterSpacing: size > 30
          ? -size * .045
          : size == 11
          ? 1.7
          : 0,
      fontWeight: weight,
      color: color,
    ),
  );
  void _jump(GlobalKey key) {
    final target = key.currentContext;
    if (target != null)
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: .08,
      );
  }

  void _open(int i) {
    AppTunnelController.select(
      [
        AppTunnel.buyer,
        AppTunnel.seller,
        AppTunnel.member,
        AppTunnel.learning,
      ][i],
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (i) {
          0 => const DealRoomsPage(initialSide: PlatformSide.business),
          1 => const SellerDashboardPage(),
          2 => const MemberDashboardPage(),
          _ => const LearningDashboardPage(),
        },
      ),
    );
  }

  Widget _button(String id, VoidCallback action, {bool outline = false}) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _copy(
            id,
            size: 14,
            color: outline ? _forest : Colors.white,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.arrow_outward, size: 18),
      ],
    );
    return outline
        ? OutlinedButton(onPressed: action, child: label)
        : FilledButton(
            onPressed: action,
            style: FilledButton.styleFrom(
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            ),
            child: label,
          );
  }

  Widget _section(Widget child, {Color color = Colors.white, Key? key}) =>
      ColoredBox(
        key: key,
        color: color,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 24 : 64,
            vertical: narrow ? 56 : 104,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: MarketingReveal(controller: _scroll, child: child),
            ),
          ),
        ),
      );
  Widget _image(int i) => SiteImage(
    contentKey: 'image.showcase.preview.${_roles[i]}',
    original: Image.asset(
      'assets/product_tours/${_roles[i]}.png',
      fit: BoxFit.contain,
      semanticLabel: '${_roles[i]} dashboard product preview',
    ),
  );
  Widget _tabs(int selected, ValueChanged<int> onChange) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < _roles.length; i++)
        ChoiceChip(
          key: ValueKey(
            'showcase-tab-${onChange == _selectPreview ? 'preview' : 'tour'}-$i',
          ),
          label: _copy(
            '${_roles[i]}.label',
            size: 13,
            color: selected == i ? Colors.white : _forest,
          ),
          selected: selected == i,
          showCheckmark: false,
          selectedColor: _forest,
          backgroundColor: Colors.white,
          onSelected: (_) => onChange(i),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        ),
    ],
  );
  void _selectPreview(int i) => setState(() => _preview = i);
  void _selectTour(int i) => setState(() => _tour = i);
  void _watch(int i) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: EdgeInsets.all(narrow ? 12 : 40),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _copy(
                      '${_roles[i]}.label',
                      size: 22,
                      weight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    tooltip: SiteContentService.text(
                      'showcase.video.close',
                      'Close video',
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: LearningMediaPlayer(
                    url: 'assets/assets/product_tours/${_roles[i]}.mp4',
                    poster: 'assets/assets/product_tours/${_roles[i]}.png',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _hero() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copy('hero.eyebrow', size: 11, weight: FontWeight.w700),
        const SizedBox(height: 34),
        _copy('hero.title', size: narrow ? 49 : 88, weight: FontWeight.w500),
        const SizedBox(height: 36),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: narrow ? double.infinity : 470,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copy('hero.intro', size: 18),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _button('hero.action', () => _jump(_spaces)),
                    TextButton.icon(
                      onPressed: () => _jump(_tours),
                      icon: const Icon(Icons.play_circle_outline),
                      label: _copy('hero.video', size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 64),
        _tabs(_preview, _selectPreview),
        const SizedBox(height: 20),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: EdgeInsets.all(narrow ? 14 : 42),
          decoration: BoxDecoration(
            color: _colors[_preview],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: KeyedSubtree(
                      key: ValueKey(_preview),
                      child: _image(_preview),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _copy('preview.caption', size: narrow ? 12 : 15),
                  ),
                  TextButton.icon(
                    onPressed: () => _watch(_preview),
                    icon: const Icon(Icons.play_circle_outline),
                    label: _copy('preview.watch', size: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _copy('preview.note', size: 11, color: const Color(0xFF67736B)),
      ],
    ),
    color: _paper,
  );
  Widget _workspaces() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copy('spaces.eyebrow', size: 11, weight: FontWeight.w700),
        const SizedBox(height: 28),
        _copy('spaces.title', size: narrow ? 42 : 68),
        const SizedBox(height: 60),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: narrow ? box.maxWidth : (box.maxWidth - 24) / 2,
                  padding: EdgeInsets.all(narrow ? 26 : 40),
                  decoration: BoxDecoration(
                    color: _colors[i],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _copy(
                            '${_roles[i]}.label',
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                          Icon(
                            [
                              Icons.travel_explore,
                              Icons.swap_horiz,
                              Icons.people_outline,
                              Icons.auto_stories_outlined,
                            ][i],
                            size: 32,
                            color: _forest,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SiteParallaxImage(
                          controller: _scroll,
                          contentKey: 'image.showcase.workspace.${_roles[i]}',
                          asset: [
                            'assets/images/pact-workshop.jpg',
                            'assets/images/affinity-reflection-facade.jpg',
                            'assets/images/commercial-atrium.jpg',
                            'assets/images/affinity-consulting.jpg',
                          ][i],
                          maxTravel: 100,
                          scrollFactor: .4,
                          child: const SizedBox(
                            height: 220,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _copy('${_roles[i]}.title', size: narrow ? 30 : 37),
                      const SizedBox(height: 20),
                      _copy('${_roles[i]}.body'),
                      const SizedBox(height: 20),
                      _copy('${_roles[i]}.features', size: 12),
                      const SizedBox(height: 26),
                      _button('${_roles[i]}.action', () => _open(i)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
    key: _spaces,
  );
  @override
  Widget build(BuildContext context) =>
      MarketingMotionScope(child: Builder(builder: _buildPage));
  Widget _buildPage(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      backgroundColor: _paper,
      surfaceTintColor: Colors.transparent,
      title: HomeBrandButton(size: narrow ? 22 : 44, dark: false),
      actions: const [
        AppNavigationMenu(
          guidePage: 'dashboards',
          dark: false,
          showPrivateUpdates: false,
        ),
        SizedBox(width: 12),
      ],
    ),
    body: SingleChildScrollView(
      controller: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(),
          _workspaces(),
          _section(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copy('tours.eyebrow', size: 11, weight: FontWeight.w700),
                const SizedBox(height: 28),
                _copy('tours.title', size: narrow ? 44 : 72),
                const SizedBox(height: 24),
                SizedBox(width: 560, child: _copy('tours.body', size: 17)),
                const SizedBox(height: 36),
                _tabs(_tour, _selectTour),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MarketingFilm(
                    key: ValueKey('inline-tour-$_tour'),
                    controller: _scroll,
                    contentKey: 'image.showcase.tour.${_roles[_tour]}',
                    imageAsset: 'assets/product_tours/${_roles[_tour]}.png',
                    videoAsset: 'assets/product_tours/${_roles[_tour]}.mp4',
                    height: narrow ? 240 : 540,
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    FilledButton.icon(
                      key: const Key('showcase-play-tour'),
                      onPressed: () => _watch(_tour),
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 24,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: _copy('preview.watch', color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            color: _paper,
            key: _tours,
          ),
          _section(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copy('closing.title', size: narrow ? 44 : 76),
                const SizedBox(height: 28),
                _copy('closing.body', size: 18),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < 4; i++)
                      _button(
                        '${_roles[i]}.action',
                        () => _open(i),
                        outline: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
