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

class _NovaTrainingHostState extends State<NovaTrainingHost> {
  late NovaTrainingController _controller;
  StreamSubscription<dynamic>? _auth;
  Route<void>? _tourRoute;
  String? _account;
  Rect? _highlight;
  final _canvas = GlobalKey();
  int _generation = 0;
  @override
  void initState() {
    super.initState();
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

  String get _initialRole => switch (Uri.base.queryParameters['module']) {
    'seller-dashboard' ||
    'seller-learning' ||
    'succession-transfer' => 'seller',
    'member-studio' ||
    'member-onboarding' ||
    'professional-onboarding' => 'member',
    _ => 'buyer',
  };
  Future<void> _load() async {
    final generation = ++_generation;
    await _controller.service.load();
    if (!mounted ||
        generation != _generation ||
        !widget.autoStart ||
        _controller.active)
      return;
    if (!_controller.service.progress.completed) {
      _controller.start(
        role: _controller.service.progress.step > 0
            ? _controller.service.progress.role
            : _initialRole,
        replay: false,
      );
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _navigate(NovaStep step) {
    _highlight = null;
    if (step.id == 'welcome')
      return; // Introduce Nova on the page the visitor opened.
    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(step));
  }

  void _locate(NovaStep step, [int attempt = 0]) {
    if (!mounted || !_controller.active || _controller.step.id != step.id)
      return;
    final context = step.target == null
        ? null
        : NovaTarget.contextFor(step.target!);
    final box = context?.findRenderObject();
    final canvas = _canvas.currentContext?.findRenderObject();
    if (box is RenderBox &&
        box.hasSize &&
        canvas is RenderBox &&
        canvas.hasSize) {
      final origin = canvas.globalToLocal(box.localToGlobal(Offset.zero));
      setState(
        () => _highlight = (origin & box.size).intersect(
          Offset.zero & canvas.size,
        ),
      );
    } else if (step.target != null && attempt < 4) {
      // Rooms load their bundle asynchronously; locate the mounted content,
      // rather than the previous route's loading frame.
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        () => _locate(step, attempt + 1),
      );
    }
  }

  void _exit() {
    final nav = widget.navigatorKey.currentState;
    final route = _tourRoute;
    _tourRoute = null;
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
  void dispose() {
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
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: NovaTourCard(controller: _controller),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class NovaTourCard extends StatelessWidget {
  const NovaTourCard({super.key, required this.controller});
  final NovaTrainingController controller;
  @override
  Widget build(BuildContext context) {
    final step = controller.step;
    final compact = MediaQuery.sizeOf(context).width < 650;
    return Material(
      color: const Color(0xFFFCFBF5),
      elevation: 14,
      shadowColor: const Color(0x553C5044),
      borderRadius: BorderRadius.circular(22),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * .62,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 18 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const SiteCopyText(
                                  'nova.panel.name',
                                  'Nova',
                                  style: TextStyle(
                                    color: Color(0xFF164F3D),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${controller.index + 1} / ${controller.steps.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF6E796F),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const Key('nova_pause'),
                            // The guide lives above the Navigator; use a semantic label
                            // instead of a tooltip that requires its Overlay.
                            onPressed: controller.saving
                                ? null
                                : controller.pause,
                            icon: Semantics(
                              label: 'Pause walkthrough',
                              child: const Icon(Icons.close_rounded, size: 19),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            child: NovaCharacter(
                              key: ValueKey(step.mood),
                              mood: step.mood,
                              size: compact ? 86 : 122,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SiteCopyText(
                                  'nova.training.${step.id}.title',
                                  step.title,
                                  style: TextStyle(
                                    color: const Color(0xFF164F3D),
                                    fontSize: compact ? 20 : 25,
                                    fontWeight: FontWeight.w700,
                                    height: 1.12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SiteCopyText(
                                  'nova.training.${step.id}.body',
                                  step.body,
                                  style: const TextStyle(
                                    color: Color(0xFF4C5A53),
                                    height: 1.5,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (step.id == 'welcome') ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (role, label) in [
                              ('buyer', 'Buying'),
                              ('seller', 'Selling / succession'),
                              ('member', 'Professional member'),
                            ])
                              ChoiceChip(
                                label: Text(label),
                                selected: controller.role == role,
                                onSelected: (_) => controller.chooseRole(role),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 24,
                0,
                compact ? 18 : 24,
                compact ? 18 : 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (controller.index + 1) / controller.steps.length,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE5EADB),
                      color: const Color(0xFF699649),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: controller.index == 0 || controller.saving
                            ? null
                            : controller.back,
                        child: const Text('Back'),
                      ),
                      if (step.id == 'welcome')
                        TextButton(
                          onPressed: controller.pause,
                          child: const Text('Later'),
                        ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: controller.saving
                                ? null
                                : controller.next,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF164F3D),
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(
                              controller.index == controller.steps.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                            label: Text(
                              controller.saving
                                  ? 'Saving…'
                                  : controller.index ==
                                        controller.steps.length - 1
                                  ? 'Finish training'
                                  : 'Next',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (step.id == 'finish')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.service.signedIn
                            ? 'Completion is saved to your profile. If offline, it stays on this device until the next sync.'
                            : 'Completion is saved on this device. Sign in to keep training progress with your profile.',
                        style: const TextStyle(
                          color: Color(0xFF6E796F),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    canvas.drawPath(path, Paint()..color = const Color(0x440B2016));
  }

  @override
  bool shouldRepaint(_Spotlight old) => old.target != target;
}

Widget novaTrainingPage(NovaStep step) {
  final parts = step.destination.split('/');
  final view = parts.length > 1 ? parts[1] : 'home';
  return switch (parts[0]) {
    'buyer' => DealRoomsPage(
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
