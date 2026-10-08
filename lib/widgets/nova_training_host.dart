import 'calculator_help_sidebar.dart';
import 'dart:math' as math;
import 'buyer_deal_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/deal_room_service.dart';
import '../services/nova_training_controller.dart';
import '../services/nova_walkthrough.dart';
import '../models/platform_side.dart';
import '../screens/deal_rooms_page.dart';
import '../screens/seller_dashboard_page.dart';
import '../screens/member_deal_marketplace_page.dart';
import '../screens/acquisition_support_page.dart';
import '../screens/transaction_learning_page.dart';
import '../screens/assistant_workspace_page.dart';
import '../screens/buyer_resources_page.dart';
import 'nova_character.dart';
import 'nova_target.dart';
import 'site_copy_text.dart';

final novaNavigatorKey = GlobalKey<NavigatorState>();

class NovaTrainingHost extends StatefulWidget {
  const NovaTrainingHost({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.controller,
    this.autoStart = true,
    this.pageBuilder,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final NovaTrainingController? controller;
  final bool autoStart;
  final Widget Function(NovaStep)? pageBuilder;
  @override
  State<NovaTrainingHost> createState() => _NovaTrainingHostState();
}

class _NovaTrainingHostState extends State<NovaTrainingHost>
    with WidgetsBindingObserver {
  late NovaTrainingController _controller;
  StreamSubscription<dynamic>? _auth;
  Route<void>? _tourRoute;
  String? _destination;
  String? _account;
  Rect? _highlight;
  final _canvas = GlobalKey();
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? NovaTrainingController.instance;
    _controller.hosted = true;
    _controller.navigate = _navigate;
    _controller.exit = _exit;
    _controller.addListener(_changed);
    _account = BackendService.user?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _auth = BackendService.authChanges?.listen((_) {
      final next = BackendService.user?.id;
      if (next == _account) return;
      _account = next;
      _controller.accountChanged();
      _load();
    });
  }

  Future<void> _load() async {
    final generation = ++_generation;
    await _controller.service.load();
    if (!mounted ||
        generation != _generation ||
        !widget.autoStart ||
        _controller.active)
      return;
    if (_controller.currentPage != 'landing' &&
        !_controller.service.progress.completed) {
      _controller.startPage(_controller.currentPage, automatic: true);
    }
  }

  void _changed() {
    if (_controller.active) CalculatorHelpController.instance.close();
    if (mounted) setState(() {});
  }

  void _navigate(NovaStep step) {
    if (_controller.pageOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate(step));
      return;
    }
    if (step.id == 'welcome') {
      setState(() => _highlight = null);
      return;
    }
    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;
    // Keep the actual page and its scroll position while moving field to field.
    if (_destination != step.destination || _tourRoute == null) {
      final page = widget.pageBuilder?.call(step) ?? novaTrainingPage(step);
      final route = PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/nova-training-preview'),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => page,
      );
      if (_tourRoute == null) {
        nav.push(route);
      } else {
        nav.pushReplacement(route);
      }
      _tourRoute = route;
      _destination = step.destination;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(step));
  }

  Future<void> _locate(NovaStep step, [int attempt = 0]) async {
    bool current() =>
        mounted && _controller.active && _controller.step.id == step.id;
    if (!current()) return;
    final targetContext = step.target == null
        ? null
        : NovaTarget.contextFor(step.target!);
    final box = targetContext?.findRenderObject();
    final canvas = _canvas.currentContext?.findRenderObject();
    if (box is RenderBox &&
        box.hasSize &&
        canvas is RenderBox &&
        canvas.hasSize) {
      Rect bounds() =>
          canvas.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
      var rect = bounds();
      if (rect.top < 90 ||
          rect.bottom > canvas.size.height * .64 ||
          rect.left < 8 ||
          rect.right > canvas.size.width - 8) {
        await Scrollable.ensureVisible(
          targetContext!,
          alignment: .28,
          duration: Duration.zero,
        );
        await WidgetsBinding.instance.endOfFrame;
        if (!current() || !box.attached || !canvas.attached) return;
        rect = bounds();
      }
      setState(() => _highlight = rect.intersect(Offset.zero & canvas.size));
    } else if (step.target != null && attempt < 30) {
      Future<void>.delayed(
        const Duration(milliseconds: 150),
        () => _locate(step, attempt + 1),
      );
    } else if (current()) {
      setState(() => _highlight = null);
    }
  }

  void _exit() {
    final nav = widget.navigatorKey.currentState;
    final route = _tourRoute;
    _tourRoute = null;
    _destination = null;
    _highlight = null;
    if (nav == null || route == null) return;
    if (_controller.savedToProfile != null) {
      // Leave a real, usable dashboard open, never the fictional example room.
      nav.pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => (widget.pageBuilder ?? novaTrainingPage)(
            NovaStep(
              'home',
              '',
              '',
              '${_controller.role}/home',
              NovaMood.welcome,
            ),
          ),
        ),
      );
    } else {
      nav.removeRoute(route);
    }
  }

  @override
  void didChangeMetrics() {
    if (_controller.active) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _locate(_controller.step),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _auth?.cancel();
    _controller.removeListener(_changed);
    _controller.hosted = false;
    _controller.navigate = null;
    _controller.exit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: _canvas,
    children: [
      ExcludeFocus(
        excluding: _controller.active,
        child: AbsorbPointer(
          absorbing: _controller.active,
          child: widget.child,
        ),
      ),
      if (_controller.active) ...[
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(painter: _Spotlight(_highlight)),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final width = math.min(470.0, size.width - 24);
              final height = math.min(
                _controller.step.id == 'welcome' ? 400.0 : 310.0,
                size.height - MediaQuery.paddingOf(context).vertical - 28,
              );
              final position = novaGuidePosition(
                size,
                Size(width, height),
                _highlight,
                MediaQuery.paddingOf(context),
              );
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 480),
                    curve: Curves.easeInOutCubic,
                    left: position.dx,
                    top: position.dy,
                    width: width,
                    height: height,
                    child: NovaTourCard(controller: _controller),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ],
  );
}

/// Place Pebble beside the target, choosing the available region with the least
/// overlap. The character and speech bubble move together; neither is docked.
Offset novaGuidePosition(
  Size screen,
  Size guide,
  Rect? target,
  EdgeInsets insets,
) {
  final area = Rect.fromLTRB(
    12,
    insets.top + 12,
    screen.width - 12,
    screen.height - insets.bottom - 12,
  );
  Offset clamp(Offset p) => Offset(
    p.dx.clamp(area.left, math.max(area.left, area.right - guide.width)),
    p.dy.clamp(area.top, math.max(area.top, area.bottom - guide.height)),
  );
  if (target == null || target.isEmpty)
    return clamp(Offset(area.right - guide.width, area.top + 80));
  final choices = [
    Offset(target.right + 18, target.center.dy - guide.height / 2),
    Offset(target.left - guide.width - 18, target.center.dy - guide.height / 2),
    Offset(target.center.dx - guide.width / 2, target.bottom + 18),
    Offset(target.center.dx - guide.width / 2, target.top - guide.height - 18),
  ].map(clamp).toList();
  double score(Offset p) {
    final rect = p & guide;
    final overlap = rect.intersect(target.inflate(8));
    return (overlap.isEmpty ? 0 : overlap.width * overlap.height * 1000) +
        (rect.center - target.center).distanceSquared;
  }

  choices.sort((a, b) => score(a).compareTo(score(b)));
  return choices.first;
}

class NovaTourCard extends StatelessWidget {
  const NovaTourCard({super.key, required this.controller});
  final NovaTrainingController controller;
  @override
  Widget build(BuildContext context) {
    final step = controller.step;
    final compact = MediaQuery.sizeOf(context).width < 650;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The supplied transparent artwork is outside the speech bubble.
        TweenAnimationBuilder<double>(
          key: ValueKey('nova-hop-${step.id}'),
          tween: Tween(begin: 0, end: 1),
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 480),
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, -math.sin(value * math.pi) * 16),
            child: child,
          ),
          child: AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            child: NovaCharacter(
              key: ValueKey(step.mood),
              mood: step.mood,
              size: compact ? 92 : 142,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: const Color(0xFFDCE4DA),
            elevation: 10,
            shadowColor: const Color(0x443C5044),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SiteCopyText(
                        'nova.panel.name',
                        'Pebble',
                        style: TextStyle(
                          color: Color(0xFF164F3D),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${controller.index + 1} / ${controller.steps.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6E796F),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          key: const Key('nova_pause'),
                          padding: EdgeInsets.zero,
                          onPressed: controller.saving
                              ? null
                              : controller.pause,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 17,
                            semanticLabel: 'Pause walkthrough',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SiteCopyText(
                            'nova.training.${step.id}.title',
                            step.title,
                            style: TextStyle(
                              color: const Color(0xFF164F3D),
                              fontSize: compact ? 17 : 20,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 9),
                          SiteCopyText(
                            'nova.training.${step.id}.body',
                            step.body,
                            style: const TextStyle(
                              color: Color(0xFF4C5A53),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                          if (step.id == 'welcome' && !controller.pageOnly) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              children: [
                                for (final (role, label) in [
                                  ('buyer', 'Buying'),
                                  ('seller', 'Selling / succession'),
                                  ('member', 'Professional member'),
                                ])
                                  ChoiceChip(
                                    label: Text(
                                      label,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    selected: controller.role == role,
                                    onSelected: (_) =>
                                        controller.chooseRole(role),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (controller.index + 1) / controller.steps.length,
                    minHeight: 3,
                    backgroundColor: const Color(0xFFE5EADB),
                    color: const Color(0xFF699649),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: controller.index == 0 || controller.saving
                            ? null
                            : controller.back,
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF164F3D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: controller.saving
                                ? null
                                : controller.next,
                            icon: Icon(
                              controller.index == controller.steps.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 15,
                            ),
                            label: Text(
                              controller.saving
                                  ? 'Saving…'
                                  : controller.index ==
                                        controller.steps.length - 1
                                  ? controller.pageOnly
                                        ? 'Done'
                                        : 'Finish training'
                                  : 'Next',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Spotlight extends CustomPainter {
  const _Spotlight(this.target);
  final Rect? target;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (target != null && !target!.isEmpty) {
      final rounded = RRect.fromRectAndRadius(
        target!.deflate(3),
        const Radius.circular(14),
      );
      path.addRRect(rounded);
      path.fillType = PathFillType.evenOdd;
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = const Color(0xFF86A963)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    // Dim the whole page slightly, including the target, then darken its surroundings.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x180B2016),
    );
    canvas.drawPath(path, Paint()..color = const Color(0x880B2016));
  }

  @override
  bool shouldRepaint(_Spotlight old) => old.target != target;
}

Widget novaTrainingPage(NovaStep step) {
  final parts = step.destination.split('/');
  final view = parts.length > 1 ? parts[1] : 'home';
  return switch (parts[0]) {
    'buyer' => DealRoomsPage(
      trainingCalculatorMode: BuyerScreenMode.values.firstWhere(
        (m) => parts.length > 2 && m.name == parts[2],
        orElse: () => BuyerScreenMode.business,
      ),
      initialSide: PlatformSide.business,
      initialView: BuyerDashboardView.values.firstWhere(
        (v) => v.name == view,
        orElse: () => BuyerDashboardView.home,
      ),
    ),
    'seller' => SellerDashboardPage(
      initialView: view == 'home'
          ? SellerDashboardView.overview
          : SellerDashboardView.values.firstWhere(
              (v) => v.name == view,
              orElse: () => SellerDashboardView.overview,
            ),
    ),
    'member' => MemberDealMarketplacePage(
      initialView: MemberDashboardView.values.firstWhere(
        (v) => v.name == view,
        orElse: () => MemberDashboardView.home,
      ),
    ),
    'room' => DealRoomPage(
      room: novaExampleBundle.room,
      initialWorkspace: view,
      trainingPreview: true,
      loadBundle: () async => novaExampleBundle,
    ),
    'blueprint' => const AcquisitionBlueprintPage(),
    'readiness' => const BuyerReadinessPage(),
    'learning' => const TransactionLearningPage(),
    'consulting' => const PersonalizedConsultingPage(),
    'resources' => const BuyerResourcesPage(),
    _ => const DealRoomsPage(initialSide: PlatformSide.business),
  };
}

final novaExampleBundle = DealRoomBundle(
  room: DealRoom(
    id: 'nova-training-example',
    userId: 'fictional-training-owner',
    title: 'Training example · Evergreen Services',
    address: '',
    city: 'Victoria',
    purchasePrice: 1200000,
    timeline: 'Fictional example — no live transaction',
    goals: 'Learn the room navigation',
    status: 'active',
    transactionType: 'business',
    dealKind: 'business',
    currentStage: 'diligence',
    propertySnapshot: {
      'annual_revenue': 1800000,
      'reported_ebitda': 260000,
      'available_capital': 300000,
    },
    riskSnapshot: {},
    sharingPreferences: {'financials': true, 'risk': true, 'documents': true},
    updatedAt: DateTime.utc(2026, 10, 5),
    totalTaskCount: 3,
    completedTaskCount: 1,
  ),
  tasks: [
    const DealRoomTask(
      id: 'training-1',
      title: 'Review financial statements',
      category: 'financial',
      completed: true,
      position: 0,
      stage: 'diligence',
    ),
    const DealRoomTask(
      id: 'training-2',
      title: 'Confirm funding plan',
      category: 'financing',
      completed: false,
      position: 1,
      stage: 'financing',
    ),
    const DealRoomTask(
      id: 'training-3',
      title: 'Prepare the handover',
      category: 'transition',
      completed: false,
      position: 2,
      stage: 'transition',
    ),
  ],
  notes: [],
  members: [],
  documents: [],
  documentEvents: [],
);
