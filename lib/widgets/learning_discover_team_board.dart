import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/member_profile_page.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import 'learning_discover_portal.dart';
import 'profile_photo.dart';
import 'team_workspace.dart';

const _boardSize = Size(560, 350);
const _ink = Color(0xff3c3027);
const _wall = Color(0xfff4eee4);
const _portraitSize = Size(153, 132);
const _portraitAngles = [-.045, .052, .038, -.042];

Offset _portraitPosition(int index) =>
    Offset(index.isEven ? 97 : 309, index < 2 ? 25 : 167);

// The strings and visible pins share the card's rotated coordinates.
Offset _portraitPin(int index) {
  final pin = Offset(index.isEven ? _portraitSize.width - 9 : 9, 43);
  final center = _portraitSize.center(Offset.zero);
  final local = pin - center;
  final angle = _portraitAngles[index];
  return _portraitPosition(index) +
      center +
      Offset(
        local.dx * math.cos(angle) - local.dy * math.sin(angle),
        local.dx * math.sin(angle) + local.dy * math.cos(angle),
      );
}

class DiscoverTeamBoard extends StatelessWidget {
  const DiscoverTeamBoard({super.key, this.interactive = false});

  final bool interactive;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: BackendService.authChanges,
    builder: (context, _) {
      final userId = BackendService.user?.id;
      return _TeamBoard(
        key: ValueKey(userId),
        userId: userId,
        interactive: interactive,
      );
    },
  );
}

class _TeamBoard extends StatefulWidget {
  const _TeamBoard({
    super.key,
    required this.userId,
    required this.interactive,
  });

  final String? userId;
  final bool interactive;

  @override
  State<_TeamBoard> createState() => _TeamBoardState();
}

class _TeamBoardState extends State<_TeamBoard> {
  late Future<List<MarketplaceProvider>> _team = AccountService.loadTeam();

  void _refresh() {
    if (mounted && widget.userId == BackendService.user?.id) {
      final team = AccountService.loadTeam();
      setState(() {
        _team = team;
      });
    }
  }

  Future<void> _manage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Manage team')),
          body: StreamBuilder(
            stream: BackendService.authChanges,
            builder: (context, _) =>
                TeamWorkspace(key: ValueKey(BackendService.user?.id)),
          ),
        ),
      ),
    );
    _refresh();
  }

  Future<void> _openProfile(MarketplaceProvider provider) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfilePage(provider: provider),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _team,
    builder: (context, snapshot) {
      final signedIn =
          widget.userId != null && widget.userId == BackendService.user?.id;
      final team = signedIn
          ? snapshot.data ?? const <MarketplaceProvider>[]
          : const <MarketplaceProvider>[];
      final unavailable = signedIn && snapshot.hasError;
      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: _boardSize,
          child: Material(
            type: MaterialType.transparency,
            child: CustomPaint(
              painter: const _TeamCork(),
              foregroundPainter: const _TeamThreads(),
              child: Stack(
                children: [
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      left: _portraitPosition(i).dx,
                      top: _portraitPosition(i).dy,
                      child: Transform.rotate(
                        angle: _portraitAngles[i],
                        child: _PortraitCard(
                          provider: i < team.length ? team[i] : null,
                          index: i,
                          onTap: !widget.interactive
                              ? null
                              : i < team.length
                              ? () => _openProfile(team[i])
                              : _manage,
                        ),
                      ),
                    ),
                  if (widget.interactive)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Center(
                        child: Material(
                          color: const Color(0xfff4e9d1),
                          borderRadius: BorderRadius.circular(4),
                          child: TextButton(
                            onPressed: unavailable ? _refresh : _manage,
                            style: TextButton.styleFrom(
                              foregroundColor: _ink,
                              minimumSize: const Size(104, 35),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              unavailable
                                  ? 'Retry loading team'
                                  : team.length > 4
                                  ? 'Manage all ${team.length} team members'
                                  : 'Manage team',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PortraitCard extends StatelessWidget {
  const _PortraitCard({
    required this.provider,
    required this.index,
    this.onTap,
  });

  final MarketplaceProvider? provider;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final member = provider;
    final role = member?.jobTitle.trim();
    return SizedBox(
      width: _portraitSize.width,
      height: _portraitSize.height,
      child: Material(
        color: const Color(0xfffcf6ea),
        elevation: 3,
        shadowColor: const Color(0x88503929),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                top: 9,
                left: 8,
                right: 8,
                bottom: 6,
                child: Column(
                  children: [
                    if (member == null)
                      const SizedBox(
                        width: 68,
                        height: 68,
                        child: ColoredBox(
                          color: Color(0xfff4f2ed),
                          child: ExcludeSemantics(
                            child: Center(
                              child: Text(
                                '?',
                                key: ValueKey('team-question-mark'),
                                style: TextStyle(
                                  fontSize: 65,
                                  height: 1,
                                  color: Color(0xff80807b),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ProfilePhoto(
                        key: ValueKey('team-photo-${member.id}'),
                        size: 68,
                        photoUrl: member.photoUrl,
                        exampleIndex: member.photoIndex,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      member?.name ?? 'Add professional',
                      key: ValueKey('team-slot-$index'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (member != null)
                      Text(
                        role == null || role.isEmpty
                            ? member.category.label
                            : role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff675445),
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCork extends CustomPainter {
  const _TeamCork();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds.shift(const Offset(3, 4)),
      paint..color = const Color(0x40342115),
    );
    canvas.drawRect(bounds, paint..color = const Color(0xff634331));
    canvas.drawRect(bounds.deflate(5), paint..color = const Color(0xff987354));
    final cork = bounds.deflate(11);
    canvas.drawRect(cork, paint..color = const Color(0xffb38559));
    final grain = math.Random(64);
    for (var i = 0; i < 1700; i++) {
      canvas.drawCircle(
        Offset(
          cork.left + grain.nextDouble() * cork.width,
          cork.top + grain.nextDouble() * cork.height,
        ),
        .2 + grain.nextDouble() * .85,
        paint
          ..color = i.isEven
              ? const Color(0x4c71492f)
              : const Color(0x38f6ce97),
      );
    }
  }

  @override
  bool shouldRepaint(_TeamCork oldDelegate) => false;
}

class _TeamThreads extends CustomPainter {
  const _TeamThreads();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final anchors = List.generate(4, _portraitPin);
    const threads = [(0, 1), (0, 3), (2, 1), (2, 3)];
    for (final (start, end) in threads) {
      canvas.drawLine(
        anchors[start].translate(0, 1.5),
        anchors[end].translate(0, 1.5),
        paint
          ..color = const Color(0x55794b32)
          ..strokeWidth = 2.6,
      );
      canvas.drawLine(
        anchors[start],
        anchors[end],
        paint
          ..color = const Color(0xffa12628)
          ..strokeWidth = 2.2,
      );
    }
    for (final pin in anchors) {
      canvas.drawCircle(
        pin.translate(1, 1.4),
        4.3,
        paint..color = const Color(0x7040291f),
      );
      canvas.drawCircle(pin, 3.8, paint..color = const Color(0xff682c28));
      canvas.drawCircle(
        pin.translate(-.9, -.9),
        1.2,
        paint..color = const Color(0xffd58b65),
      );
    }
  }

  @override
  bool shouldRepaint(_TeamThreads oldDelegate) => false;
}

class DiscoverTeamBoardRoute extends PageRouteBuilder<void> {
  DiscoverTeamBoardRoute(Rect source)
    : super(
        opaque: false,
        transitionDuration: discoverPaperDuration,
        reverseTransitionDuration: discoverPaperReverseDuration,
        pageBuilder: (context, animation, _) => AnimatedBuilder(
          animation: animation,
          builder: (context, _) => LayoutBuilder(
            builder: (context, bounds) {
              final time = animation.value;
              final size = bounds.biggest;
              final width = math.max(
                1.0,
                math.min(
                  940.0,
                  math.min(
                    size.width - 22,
                    (size.height - 64) * _boardSize.aspectRatio,
                  ),
                ),
              );
              final target = Rect.fromCenter(
                center: size.center(const Offset(0, 20)),
                width: width,
                height: width / _boardSize.aspectRatio,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: _wall.withValues(
                        alpha: discoverPaperBackdrop.transform(time),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: Rect.lerp(
                      source,
                      target,
                      discoverPaperZoom.transform(time),
                    )!,
                    child: DiscoverTeamBoard(interactive: time == 1),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: IgnorePointer(
                        ignoring: time < 1,
                        child: Opacity(
                          opacity: const Interval(.7, 1).transform(time),
                          child: const Material(
                            type: MaterialType.transparency,
                            child: SizedBox(
                              height: 46,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: BackButton(),
                                  ),
                                  Text(
                                    'My team',
                                    style: TextStyle(color: _ink, fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

  @override
  AnimationController createAnimationController() => AnimationController(
    vsync: navigator!,
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
}
