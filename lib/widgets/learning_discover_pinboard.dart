import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/discover_activity.dart';
import '../services/marketplace_service.dart';

const _notes = [
  Color(0xffead481),
  Color(0xffe8b7a8),
  Color(0xffc2d0ac),
  Color(0xffb5cad3),
  Color(0xffe9d3a7),
  Color(0xffd3c4dc),
  Color(0xffebdb99),
];

const _noteTitles = [
  'Files opened',
  'Deals viewed',
  'My team',
  'Best 5 files',
  'Note 5',
  'Note 6',
  'Note 7',
];

class DiscoverPinboard extends StatelessWidget {
  const DiscoverPinboard({super.key, this.openNote, this.writing = 0});
  final ValueChanged<int>? openNote;
  final double writing;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.6,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xffb88f66),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xff75503a), width: 8),
        ),
        boxShadow: [BoxShadow(color: Color(0x3332261c), offset: Offset(5, 6))],
      ),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final w = bounds.maxWidth;
          final h = bounds.maxHeight;
          final noteWidth = w * .215;
          final noteHeight = h * .39;
          return Stack(
            children: [
              for (var i = 0; i < _notes.length; i++)
                Positioned(
                  left: i < 4
                      ? w * (.047 + i * .23)
                      : w * (.156 + (i - 4) * .242),
                  top: h * (i < 4 ? .085 : .53),
                  width: noteWidth,
                  height: noteHeight,
                  child: Transform.rotate(
                    angle: const [-.09, .06, -.045, .075, .05, -.065, .08][i],
                    child: Material(
                      color: _notes[i],
                      elevation: 2,
                      child: InkWell(
                        onTap: openNote == null ? null : () => openNote!(i),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const Alignment(0, -.86),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Color(0xff923a36),
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.square(dimension: h * .035),
                              ),
                            ),
                            if (writing > 0)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    _writtenTitle(i),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xff4d3829),
                                      fontSize: noteWidth * .115,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
  String _writtenTitle(int index) {
    final start = index * .069;
    final progress = ((writing - start) / .46).clamp(0.0, 1.0);
    final title = _noteTitles[index];
    final count = (title.length * progress).floor();
    if (progress == 0) return '';
    return title.substring(0, count) + (count == title.length ? '' : '▏');
  }
}

class DiscoverPinboardRoute extends PageRouteBuilder<void> {
  DiscoverPinboardRoute(Rect source)
    : super(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 2150),
        reverseTransitionDuration: const Duration(milliseconds: 620),
        pageBuilder: (context, animation, _) =>
            _ZoomedPinboard(source: source, animation: animation),
      );

  @override
  AnimationController createAnimationController() => AnimationController(
    vsync: navigator!,
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
}

class _ZoomedPinboard extends StatelessWidget {
  const _ZoomedPinboard({required this.source, required this.animation});
  final Rect source;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final time = animation.value;
      final zoom = const Interval(
        0,
        .84,
        curve: Curves.easeInOutCubic,
      ).transform(time);
      final ink = const Interval(.48, 1).transform(time);
      return LayoutBuilder(
        builder: (context, bounds) {
          final size = bounds.biggest;
          final width = math.max(
            1.0,
            math.min(size.width - 36, (size.height - 84) * 1.6),
          );
          final destination = Rect.fromCenter(
            center: size.center(const Offset(0, 24)),
            width: width,
            height: width / 1.6,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xfff4eee4).withValues(
                    alpha: const Interval(
                      0,
                      .60,
                      curve: Curves.easeInOut,
                    ).transform(time),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: Rect.lerp(source, destination, zoom)!,
                child: DiscoverPinboard(
                  writing: ink,
                  openNote: time == 1
                      ? (index) => _openNote(context, index)
                      : null,
                ),
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
                      child: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          height: 55,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: BackButton(),
                              ),
                              Text(
                                'Discover pinboard',
                                style: Theme.of(context).textTheme.titleLarge,
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
      );
    },
  );

  Future<void> _openNote(BuildContext context, int index) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: _notes[index],
      child: SizedBox(
        width: 500,
        height: 365,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _noteTitles[index],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close note',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(child: _noteContent(index)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _noteContent(int index) {
    if (index == 3)
      return const Center(
        child: Text('Your starter-file recommendations are coming soon.'),
      );
    if (index > 3) return const SizedBox.shrink();
    return StreamBuilder(
      stream: BackendService.authChanges,
      builder: (context, _) {
        final userId = BackendService.user?.id;
        if (userId == null) {
          return const Center(
            child: Text('Sign in to see your activity and team.'),
          );
        }
        return _PrivateNote(
          key: ValueKey(userId),
          index: index,
          userId: userId,
        );
      },
    );
  }
}

class _PrivateNote extends StatefulWidget {
  const _PrivateNote({required this.index, required this.userId, super.key});

  final int index;
  final String userId;

  @override
  State<_PrivateNote> createState() => _PrivateNoteState();
}

class _PrivateNoteState extends State<_PrivateNote> {
  late Future<Object> _data = _load();

  Future<Object> _load() => widget.index == 2
      ? AccountService.loadTeam()
      : DiscoverActivity.count(
          widget.userId,
          widget.index == 0
              ? DiscoverActivityKind.files
              : DiscoverActivityKind.deals,
        );

  @override
  Widget build(BuildContext context) => FutureBuilder<Object>(
    future: _data,
    builder: (context, snapshot) {
      if (BackendService.user?.id != widget.userId)
        return const SizedBox.shrink();
      if (snapshot.hasError) {
        return Center(
          child: TextButton(
            onPressed: () => setState(() => _data = _load()),
            child: const Text('Could not load this note. Try again'),
          ),
        );
      }
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final data = snapshot.data;
      if (data is List<MarketplaceProvider>) {
        if (data.isEmpty)
          return const Center(child: Text('Your saved team is empty.'));
        return ListView(
          children: [
            for (final member in data)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(member.name),
                subtitle:
                    member.jobTitle.isNotEmpty || member.company.isNotEmpty
                    ? Text(
                        [
                          member.jobTitle,
                          member.company,
                        ].where((part) => part.isNotEmpty).join(' · '),
                      )
                    : null,
              ),
          ],
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$data', style: Theme.of(context).textTheme.displaySmall),
            Text(
              widget.index == 0
                  ? 'Unique files opened in this browser'
                  : 'Unique deals viewed in this browser',
            ),
          ],
        ),
      );
    },
  );
}
