import '../services/site_content_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'site_copy_text.dart';

double organizerWidth(double screenWidth) => screenWidth < 700
    ? (screenWidth * (screenWidth < 360 ? .58 : .60)).clamp(186.0, 280.0)
    : screenWidth < 900
    ? 388
    : 420;

/// Optional page palette; existing navigation keeps its established colours.
class NavigationOrganizerPalette {
  const NavigationOrganizerPalette({
    this.active = const Color(0xFF142916),
    this.activeText = const Color(0xFFBDD89D),
    this.text = const Color(0xFF172817),
    this.hover = const Color(0xFFE8EBE5),
  });
  final Color active, activeText, text, hover;
}

/// A viewport-centred organizer, with a click-open dashboard panel.
class NavigationOrganizer extends StatefulWidget {
  const NavigationOrganizer({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onAbout,
    this.onDashboard,
    this.onPreview,
    this.previewLabel = 'Design preview',
    this.previewContentKey = 'navigation.organizer.preview',
    this.palette = const NavigationOrganizerPalette(),
    this.initiallyOpen = false,
    this.compactTrailingSpace = 0,
    required this.dashboards,
  });
  final NavigationOrganizerPalette palette;
  final String previewLabel, previewContentKey;
  final int activeTab;
  final bool initiallyOpen;
  final double compactTrailingSpace;
  final VoidCallback onHome, onAbout;
  final VoidCallback? onDashboard, onPreview;
  final List<Widget> dashboards;
  @override
  State<NavigationOrganizer> createState() => NavigationOrganizerState();
}

class NavigationOrganizerState extends State<NavigationOrganizer> {
  late bool _open;
  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
    if (_open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) _panelFocus.requestFocus();
      });
    }
  }

  int? _hovered;
  final _dashboardFocus = FocusNode();
  final _panelFocus = FocusNode();
  void close() {
    if (_open && mounted) setState(() => _open = false);
  }

  @override
  void dispose() {
    _dashboardFocus.dispose();
    _panelFocus.dispose();
    super.dispose();
  }

  void _choose(int tab) {
    if (tab == 3) {
      close();
      widget.onPreview?.call();
      return;
    }
    if (tab == 1 && widget.onDashboard != null) {
      widget.onDashboard!();
      return;
    }
    if (tab == 1) {
      setState(() => _open = !_open);
      if (_open)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _open) _panelFocus.requestFocus();
        });
    } else {
      close();
      (tab == 0 ? widget.onHome : widget.onAbout)();
    }
  }

  void toggleMenu() {
    setState(() => _open = !_open);
    if (_open)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) _panelFocus.requestFocus();
      });
  }

  Widget _bar(double width) => Material(
    color: const Color(0xFFFCFCFA),
    elevation: 2,
    shadowColor: const Color(0x160F2418),
    borderRadius: BorderRadius.circular(40),
    child: SizedBox(
      key: const Key('affinity-navigation-bar'),
      width: width,
      height: 52,
      child: MouseRegion(
        onExit: (_) => setState(() => _hovered = null),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: LayoutBuilder(
            builder: (context, box) {
              final weights = widget.onPreview == null
                  ? [.8, 1.4, 1.0]
                  : widget.previewLabel == 'X2'
                  ? [.8, 1.4, 1.0, .55]
                  : [.7, 1.15, .9, 1.15];
              final unit =
                  box.maxWidth / weights.fold<double>(0, (a, b) => a + b);
              final widths = weights.map((weight) => unit * weight).toList();
              final starts = <double>[0];
              for (var i = 1; i < widths.length; i++) {
                starts.add(starts.last + widths[i - 1]);
              }
              return Stack(
                children: [
                  AnimatedPositioned(
                    key: const Key('navigation-hover-highlight'),
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    bottom: 0,
                    left: starts[_hovered ?? widget.activeTab],
                    width: widths[_hovered ?? widget.activeTab],
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: _hovered == null ? 0 : 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.palette.hover,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(32),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < widths.length; i++)
                        SizedBox(
                          width: widths[i],
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hovered = i),
                            child: Semantics(
                              button: true,
                              selected: widget.activeTab == i,
                              expanded: i == 1 ? _open : null,
                              child: InkWell(
                                key: ValueKey('organizer-tab-$i'),
                                focusNode: i == 1 ? _dashboardFocus : null,
                                onFocusChange: (focused) {
                                  if (focused) setState(() => _hovered = i);
                                },
                                onTap: () => _choose(i),
                                borderRadius: BorderRadius.circular(32),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: widget.activeTab == i
                                        ? widget.palette.active
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SiteCopyText(
                                            [
                                              'navigation.home',
                                              'navigation.organizer.dashboard',
                                              'navigation.organizer.about',
                                              widget.previewContentKey,
                                            ][i],
                                            [
                                              'Home',
                                              'Dashboard',
                                              'About us',
                                              widget.previewLabel,
                                            ][i],
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: width < 280 ? 12 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: widget.activeTab == i
                                                  ? widget.palette.activeText
                                                  : widget.palette.text,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (i == 1 && widget.onDashboard != null)
                                        SizedBox(
                                          width: width < 280 ? 16 : 22,
                                          height: 36,
                                          child: IconButton(
                                            key: const Key(
                                              'dashboard-menu-toggle',
                                            ),
                                            tooltip: SiteContentService.text(
                                              'navigation.organizer.choose',
                                              'Choose a dashboard',
                                            ),
                                            padding: EdgeInsets.zero,
                                            iconSize: width < 280 ? 13 : 17,
                                            onPressed: () => _choose(1),
                                            icon: Icon(
                                              _open
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: widget.activeTab == 1
                                                  ? widget.palette.activeText
                                                  : widget.palette.text,
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
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final reserveActions =
        screen.width < 700 && widget.compactTrailingSpace > 0;
    return SizedBox.expand(
      child: Stack(
        children: [
          if (_open) ...[
            Positioned.fill(
              child: GestureDetector(
                key: const Key('organizer-dismiss'),
                behavior: HitTestBehavior.opaque,
                onTap: close,
                child: const ColoredBox(color: Color(0x08000000)),
              ),
            ),
            Positioned(
              top: safeTop + 76,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: Focus(
                  focusNode: _panelFocus,
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.escape) {
                      close();
                      _dashboardFocus.requestFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Material(
                    key: const Key('dashboard-navigation-panel'),
                    color: const Color(0xFFFCFCFA),
                    elevation: 12,
                    shadowColor: const Color(0x250A2113),
                    borderRadius: BorderRadius.circular(30),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 1000,
                        maxHeight: screen.height - safeTop - 100,
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(screen.width < 700 ? 16 : 32),
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final columns = box.maxWidth >= 760
                                ? 4
                                : box.maxWidth >= 440
                                ? 2
                                : 1;
                            final width =
                                (box.maxWidth - (columns - 1) * 14) / columns;
                            return Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                for (final item in widget.dashboards)
                                  SizedBox(width: width, child: item),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            top: safeTop + 14,
            left: reserveActions ? 76 : 0,
            right: reserveActions ? widget.compactTrailingSpace : 0,
            child: LayoutBuilder(
              builder: (context, box) => Center(
                child: _bar(
                  organizerWidth(screen.width).clamp(0.0, box.maxWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
