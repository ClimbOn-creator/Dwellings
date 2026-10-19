import '../services/site_content_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'site_copy_text.dart';

double organizerWidth(double screenWidth) => screenWidth < 700
    ? (screenWidth * (screenWidth < 360 ? .58 : .60)).clamp(186.0, 280.0)
    : screenWidth < 900
    ? 388
    : 420;

/// A viewport-centred organizer, with a click-open dashboard panel.
class NavigationOrganizer extends StatefulWidget {
  const NavigationOrganizer({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onAbout,
    this.onDashboard,
    required this.dashboards,
  });
  final int activeTab;
  final VoidCallback onHome, onAbout;
  final VoidCallback? onDashboard;
  final List<Widget> dashboards;
  @override
  State<NavigationOrganizer> createState() => NavigationOrganizerState();
}

class NavigationOrganizerState extends State<NavigationOrganizer> {
  bool _open = false;
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
    if (tab == 1 && widget.onDashboard != null) {
      close();
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

  void _toggleMenu() {
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
              final unit = box.maxWidth / 3.2;
              final widths = [unit * .8, unit * 1.4, unit];
              final starts = [0.0, widths[0], widths[0] + widths[1]];
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
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE8EBE5),
                          borderRadius: BorderRadius.all(Radius.circular(32)),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        SizedBox(
                          width: widths[i],
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hovered = i),
                            child: Semantics(
                              button: true,
                              selected: widget.activeTab == i,
                              expanded: i == 1 && widget.onDashboard == null
                                  ? _open
                                  : null,
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
                                        ? const Color(0xFF142916)
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
                                            ][i],
                                            [
                                              'Home',
                                              'Dashboard',
                                              'About us',
                                            ][i],
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: width < 280 ? 12 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: widget.activeTab == i
                                                  ? const Color(0xFFBDD89D)
                                                  : const Color(0xFF172817),
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
                                            onPressed: _toggleMenu,
                                            icon: Icon(
                                              _open
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: widget.activeTab == 1
                                                  ? const Color(0xFFBDD89D)
                                                  : const Color(0xFF172817),
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
            left: 0,
            right: 0,
            child: Center(child: _bar(organizerWidth(screen.width))),
          ),
        ],
      ),
    );
  }
}
