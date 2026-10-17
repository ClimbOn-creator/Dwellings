import '../widgets/membership_footer.dart';
import '../widgets/dashboard_header.dart';
import 'deal_rooms_page.dart';
import 'deal_comparison_page.dart';
import 'dart:async';
import '../widgets/canada_event_map.dart';
import '../widgets/learning_example_cover.dart';
import '../services/learning_examples.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show RealtimeChannel, PostgresChangeEvent;
import '../services/backend_service.dart';
import '../services/app_tunnel.dart';
import '../services/learning_service.dart';
import '../models/learning_journey.dart';
import '../models/platform_side.dart';
import '../widgets/dashboard_ui.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/learning_media_player.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/nova_target.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';
import 'transaction_learning_page.dart';
import 'buyer_resources_page.dart';
import '../services/learning_area_service.dart';
import '../services/nova_training_controller.dart';
import '../widgets/learning_area_picker.dart';
import '../widgets/learning_comments.dart';

enum LearningView {
  feed,
  seminars,
  map,
  quiz,
  pipeline,
  resources,
  contributors,
}

class LearningDashboardPage extends StatefulWidget {
  const LearningDashboardPage({
    super.key,
    this.initialView = LearningView.feed,
    this.loadPosts,
    this.loadSeminars,
    this.loadPermissions,
  });
  final LearningView initialView;
  final Future<List<LearningPost>> Function()? loadPosts;
  final Future<List<LearningSeminar>> Function()? loadSeminars;
  final Future<LearningPermissions> Function()? loadPermissions;
  @override
  State<LearningDashboardPage> createState() => _LearningDashboardPageState();
}

class _LearningDashboardPageState extends State<LearningDashboardPage> {
  late LearningView view;
  Future<List<LearningPost>>? _feedFuture;
  Future<List<LearningSeminar>>? _seminarsFuture;
  LearningArea? area;
  final exampleLikes = <String>{};
  final exampleThreads = <String, List<LearningComment>>{};
  Future<List<LearningPost>> get feed => _feedFuture ??= _loadFeed();
  Future<List<LearningPost>> _loadFeed() async {
    if (widget.loadPosts != null) return widget.loadPosts!();
    return LearningService.posts(order: 'newest');
  }

  Future<void> _loadArea() async {
    final uid = BackendService.user?.id;
    final value = await LearningAreaService.load();
    if (mounted && uid == BackendService.user?.id) setState(() => area = value);
  }

  Future<void> _comments(LearningPost post) async {
    final controller = NovaTrainingController.instance;
    final wasDocked = controller.docked;
    if (wasDocked) controller.dismissDock();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) => SizedBox(
          height: MediaQuery.sizeOf(c).height * .9,
          child: LearningComments(
            post: post,
            isOwner: permissions.isOwner,
            exampleComments: post.exampleIndex == null
                ? null
                : exampleThreads.putIfAbsent(
                    post.id,
                    () => LearningExamples.commentsFor(post),
                  ),
            onExampleChanged: (values) {
              if (mounted) setState(() => exampleThreads[post.id] = values);
            },
          ),
        ),
      );
    } finally {
      if (wasDocked) controller.restoreDock();
    }
    if (mounted) refresh();
  }

  Future<List<LearningSeminar>> get seminars =>
      _seminarsFuture ??= (widget.loadSeminars ?? LearningService.seminars)();
  LearningPermissions permissions = const LearningPermissions();
  StreamSubscription? auth;
  Timer? clock;
  RealtimeChannel? eventChanges;
  int eventRevision = 0;
  bool updatingEvents = false;

  bool seller = false, busy = false;
  int selected = 0;
  int? answer;
  Set<String> completed = {};
  String? progressNotice;
  List<LearningPhase> get journey =>
      seller ? sellerLearningJourney : buyerLearningJourney;
  LearningPhase get phase => journey[selected];
  @override
  void initState() {
    super.initState();
    view = widget.initialView;
    _loadArea();
    refresh();
    auth = BackendService.authChanges?.listen((_) {
      if (mounted) {
        setState(() {
          permissions = const LearningPermissions();
          area = null;
          _loadArea();
        });
        refresh();
      }
    });
    if (BackendService.configured && widget.loadSeminars == null) {
      eventChanges = LearningService.client
          .channel('learning-events-${identityHashCode(this)}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'learning_seminars',
            callback: (_) => _refreshEvents(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'learning_event_images',
            callback: (_) => _refreshEvents(),
          )
          .subscribe();
    }
    // Polling also handles revoked hosts and rows that become invisible to RLS,
    // and keeps the map current after a dropped realtime connection.
    clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && view == LearningView.seminars) {
        _refreshEvents();
        _loadPermissions();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    auth?.cancel();
    clock?.cancel();
    if (eventChanges != null)
      LearningService.client.removeChannel(eventChanges!);
    super.dispose();
  }

  Future<void> _refreshEvents() async {
    if (!mounted) return;
    if (view != LearningView.seminars) {
      _seminarsFuture = null;
      return;
    }
    if (updatingEvents) return;
    updatingEvents = true;
    final revision = eventRevision;
    final uid = BackendService.user?.id;
    try {
      final values = await (widget.loadSeminars ?? LearningService.seminars)();
      if (mounted &&
          revision == eventRevision &&
          uid == BackendService.user?.id) {
        setState(() => _seminarsFuture = Future.value(values));
      }
    } catch (_) {
      // Keep the last confirmed events during temporary network failures.
    } finally {
      updatingEvents = false;
    }
  }

  void refresh() {
    eventRevision++;
    _feedFuture = null;
    _seminarsFuture = null;
    _loadPermissions();
    _progress();
    if (mounted) setState(() {});
  }

  Future<void> _loadPermissions() async {
    final uid = BackendService.user?.id;
    try {
      final p = await (widget.loadPermissions ?? LearningService.permissions)();
      if (mounted && BackendService.user?.id == uid)
        setState(() => permissions = p);
    } catch (_) {
      if (mounted) setState(() => permissions = const LearningPermissions());
    }
  }

  Future<void> _progress() async {
    final uid = BackendService.user?.id;
    final prefs = await SharedPreferences.getInstance();
    var values =
        (prefs.getStringList('learning.progress.${uid ?? 'guest'}') ?? [])
            .toSet();
    try {
      if (uid != null) values = await LearningService.progress();
    } catch (_) {}
    if (mounted && BackendService.user?.id == uid)
      setState(() => completed = values);
  }

  Future<void> _mark() async {
    final id = phase.id;
    final values = {...completed};
    if (!values.add(id)) values.remove(id);
    final uid = BackendService.user?.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'learning.progress.${uid ?? 'guest'}',
      values.toList(),
    );
    if (!mounted || BackendService.user?.id != uid) return;
    setState(() {
      completed = values;
      progressNotice = uid == null
          ? 'Progress saved on this device. Sign in to keep it with your account.'
          : null;
    });
    try {
      await LearningService.markConcept(id, values.contains(id));
    } catch (_) {
      if (mounted)
        setState(
          () => progressNotice =
              'Saved on this device. Account sync failed; try again when connected.',
        );
    }
  }

  Future<bool> _signedIn() async {
    if (BackendService.user != null) return true;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
    if (mounted) refresh();
    return mounted && BackendService.user != null;
  }

  Future<void> _action(Future<void> Function() call) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await call();
      if (mounted) refresh();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete this action: $e')),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget copy(
    String id,
    String value, {
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) => SiteCopyText(
    id,
    value,
    style: TextStyle(
      fontSize: size,
      color: color ?? DashboardUi.ink,
      fontWeight: weight,
      height: 1.45,
    ),
  );
  String get guide =>
      view == LearningView.quiz ? 'comparison' : 'learning-${view.name}';
  void show(LearningView next) {
    setState(() => view = next);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: DashboardUi.theme(Theme.of(context)),
    child: Scaffold(
      backgroundColor: DashboardUi.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        backgroundColor: const Color(0xFFF7F5F0),
        surfaceTintColor: Colors.transparent,
        title: const DashboardHeader(
          label: 'Learning dash',
          contentKey: 'dashboard.header.learning',
        ),
        actions: [
          AppNavigationMenu(
            guidePage: guide,
            dark: false,
            showPrivateUpdates: false,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= 900
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sidebar(),
                  const VerticalDivider(width: 1, color: DashboardUi.line),
                  Expanded(child: _workspace(false)),
                ],
              )
            : _workspace(true),
      ),
    ),
  );
  Widget _sidebar() => Container(
    width: 212,
    color: Colors.white,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(13, 24, 13, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 0, 0, 18),
            child: copy(
              'learning.nav.workspace',
              'LEARNING',
              size: 10,
              color: DashboardUi.muted,
              weight: FontWeight.w800,
            ),
          ),
          for (final item in const [
            (LearningView.feed, 'Learning feed', Icons.home_outlined),
            (LearningView.seminars, 'Live seminars', Icons.videocam_outlined),
            (
              LearningView.map,
              'Buying & selling map',
              Icons.account_tree_outlined,
            ),
            (LearningView.quiz, 'Deal comparison quiz', Icons.compare_arrows),
            (LearningView.pipeline, 'Pipeline', Icons.view_kanban_outlined),
            (LearningView.resources, 'Resources', Icons.public),
          ])
            DashboardUi.nav(
              item.$2,
              item.$3,
              view == item.$1,
              () => show(item.$1),
            ),
          if (permissions.isOwner)
            DashboardUi.nav(
              'Contributor approvals',
              Icons.verified_user_outlined,
              view == LearningView.contributors,
              () => show(LearningView.contributors),
            ),
          const SizedBox(height: 32),
          DashboardUi.nav('Refresh', Icons.refresh, false, refresh),
        ],
      ),
    ),
  );
  Widget _compactNavigation() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final v in LearningView.values.where(
          (v) => v != LearningView.contributors || permissions.isOwner,
        ))
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(v)),
              selected: view == v,
              onSelected: (_) => show(v),
            ),
          ),
      ],
    ),
  );

  Widget _workspace(bool compact) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(
        offstage: view == LearningView.seminars,
        child: TickerMode(
          enabled: view != LearningView.seminars,
          child: _standardWorkspace(compact),
        ),
      ),
      if (view == LearningView.seminars)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: _compactNavigation(),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: box.maxHeight,
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 8 : 12),
                          child: _seminars(),
                        ),
                      ),
                      const MembershipFooter(fullBleed: false),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    ],
  );

  Widget _standardWorkspace(bool compact) => SingleChildScrollView(
    padding: EdgeInsets.all(
      compact ? (view == LearningView.quiz ? 12 : 18) : 28,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact) ...[_compactNavigation(), const SizedBox(height: 22)],
            Offstage(
              offstage: view != LearningView.quiz,
              child: TickerMode(
                enabled: view == LearningView.quiz,
                child: const DealComparisonPage(embedded: true),
              ),
            ),
            switch (view) {
              LearningView.feed => _feed(),
              LearningView.seminars => const SizedBox.shrink(),
              LearningView.map => _map(),
              LearningView.quiz => const SizedBox.shrink(),
              LearningView.pipeline => DealRoomsPage(
                key: ValueKey(BackendService.user?.id),
                embeddedPipeline: true,
              ),
              LearningView.resources => const BuyerResourcesPanel(),
              LearningView.contributors => _contributors(),
            },
            const SizedBox(height: 36),
            const MembershipFooter(fullBleed: false),
          ],
        ),
      ),
    ),
  );
  String _label(LearningView v) => switch (v) {
    LearningView.feed => 'Learning feed',
    LearningView.seminars => 'Live seminars',
    LearningView.map => 'Buying & selling map',
    LearningView.quiz => 'Deal comparison quiz',
    LearningView.pipeline => 'Pipeline',
    LearningView.resources => 'Resources',
    LearningView.contributors => 'Contributor approvals',
  };
  Widget heading(String id, String title, String intro) => NovaTarget(
    id: '$guide.title',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        copy('learning.$id.title', title, size: 28, weight: FontWeight.w800),
        const SizedBox(height: 8),
        copy('learning.$id.intro', intro, size: 14, color: DashboardUi.muted),
        const SizedBox(height: 24),
      ],
    ),
  );
  Widget _feed() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (permissions.canPublish)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: FilledButton.icon(
            onPressed: busy ? null : _compose,
            icon: const Icon(Icons.add),
            label: copy(
              'learning.feed.publish',
              'Create a learning post',
              color: Colors.white,
            ),
          ),
        ),
      FutureBuilder<List<LearningPost>>(
        future: feed,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return _error(
              'The learning feed could not load. Please try again.',
            );
          final published = snapshot.data ?? [];
          final all = published.isEmpty ? LearningExamples.posts : published;
          final shown = all;
          return NovaTarget(
            id: 'learning-feed.posts',
            child: Column(
              children: [
                if (shown.isEmpty)
                  DashboardUi.panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy(
                          'learning.feed.empty',
                          'No learning posts yet',
                          size: 20,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(height: 8),
                        copy(
                          'learning.feed.empty.detail',
                          'Only creator-approved contributors can publish. Explore the learning map or document guides while new lessons arrive.',
                          color: DashboardUi.muted,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => show(LearningView.map),
                              icon: const Icon(Icons.account_tree_outlined),
                              label: copy(
                                'learning.feed.map',
                                'Explore the learning map',
                              ),
                            ),
                            TextButton(
                              onPressed: _documents,
                              child: copy(
                                'learning.feed.documents',
                                'Document examples',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                for (final p in shown) ...[
                  _post(p),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 24),
                _startHere(),
              ],
            ),
          );
        },
      ),
    ],
  );
  Widget _startHere() => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        copy(
          'learning.start.title',
          'Start with the concepts',
          size: 20,
          weight: FontWeight.w700,
        ),
        const SizedBox(height: 12),
        copy(
          'learning.start.body',
          'Use the interactive map to understand each stage, then explore the documents and examples. Pika can show you around this page.',
          color: DashboardUi.muted,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  seller = false;
                  selected = 0;
                  answer = null;
                  view = LearningView.map;
                });
              },
              icon: const Icon(Icons.business_center_outlined),
              label: copy('learning.start.buy', 'Buying a business'),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  seller = true;
                  selected = 0;
                  answer = null;
                  view = LearningView.map;
                });
              },
              icon: const Icon(Icons.handshake_outlined),
              label: copy('learning.start.sell', 'Succession or transfer'),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _post(LearningPost p) => Align(
    key: ValueKey('learning-post-${p.id}'),
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: DashboardUi.panel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: DashboardUi.paleBlue,
                  child: Text(p.author.isEmpty ? '?' : p.author[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.author,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${p.areaName ?? "Community post"}${p.distanceKm == null ? "" : " · ~${p.distanceKm!.round()} km"} · ${DateFormat('MMM d').format(p.createdAt)}',
                        style: const TextStyle(
                          color: DashboardUi.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.exampleIndex != null)
                  const Chip(label: Text('Example'))
                else
                  const Tooltip(
                    message: 'Creator-approved contributor',
                    child: Icon(
                      Icons.verified,
                      color: DashboardUi.blue,
                      size: 21,
                    ),
                  ),
                if (p.exampleIndex == null &&
                    (permissions.isOwner ||
                        p.authorId == BackendService.user?.id))
                  IconButton(
                    tooltip: 'Hide this post',
                    onPressed: busy ? null : () => _confirmHide(p),
                    icon: const Icon(Icons.more_horiz),
                  ),
              ],
            ),
            if (p.exampleIndex != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: MediaQuery.sizeOf(context).width < 600 ? 260 : 420,
                width: double.infinity,
                child: LearningExampleCover(index: p.exampleIndex!),
              ),
            ],
            if (p.media.isNotEmpty) ...[
              const SizedBox(height: 18),
              LearningGallery(media: p.media),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 18,
              children: [
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          if (p.exampleIndex != null) {
                            setState(() {
                              if (!exampleLikes.add(p.id))
                                exampleLikes.remove(p.id);
                            });
                            return;
                          }
                          if (await _signedIn())
                            _action(
                              () =>
                                  LearningService.reaction(p, 'like', !p.liked),
                            );
                        },
                  icon: Icon(
                    (p.exampleIndex != null
                            ? exampleLikes.contains(p.id)
                            : p.liked)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  label: Text(
                    '${p.likes + (exampleLikes.contains(p.id) ? 1 : 0)} ${p.likes + (exampleLikes.contains(p.id) ? 1 : 0) == 1 ? 'like' : 'likes'}',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _comments(p),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(
                    '${exampleThreads[p.id]?.where((c) => !c.removed).length ?? p.comments} ${(exampleThreads[p.id]?.where((c) => !c.removed).length ?? p.comments) == 1 ? 'comment' : 'comments'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (p.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              LearningCaption(key: ValueKey(p.id), body: p.body),
            ],
            const SizedBox(height: 18),
            const Divider(color: DashboardUi.line),
          ],
        ),
      ),
    ),
  );
  Future<void> _confirmHide(LearningPost p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hide this learning post?'),
        content: const Text(
          'It will leave the public feed. Its records are retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hide post'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) _action(() => LearningService.hidePost(p.id));
  }

  Widget _error(String message) => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
  void _documents() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const TransactionLearningPage()),
  );
  Future<void> _compose() async {
    await showDialog<void>(
      context: context,
      builder: (_) => LearningPostComposer(initialArea: area),
    );
    if (mounted) refresh();
  }

  Future<void> _manageEvents() async {
    final events = await seminars;
    if (!mounted) return;
    final mine = events
        .where(
          (e) => permissions.isOwner || e.hostId == BackendService.user?.id,
        )
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: SiteCopyText(
                        'learning.events.manage.title',
                        'Manage your events',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (mine.isEmpty)
                  const SiteCopyText(
                    'learning.events.manage.empty',
                    'No published events to manage yet.',
                  ),
                for (final event in mine)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _seminar(event),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _seminars() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (permissions.canPublish)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _schedule,
                icon: const Icon(Icons.add),
                label: const Text('Place an event on the map'),
              ),
              TextButton.icon(
                onPressed: _manageEvents,
                icon: const Icon(Icons.event_note_outlined),
                label: const SiteCopyText(
                  'learning.events.manage.action',
                  'Manage events',
                ),
              ),
            ],
          ),
        ),
      Expanded(
        child: NovaTarget(
          id: 'learning-seminars.sessions',
          child: FutureBuilder<List<LearningSeminar>>(
            future: seminars,
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return _error('Seminars could not load. Please try again.');
              final events = [
                ...snapshot.data ?? <LearningSeminar>[],
                ...LearningExamples.events,
              ].where((e) => e.visibleOnMap(DateTime.now())).toList();
              return NovaTarget(
                id: 'learning-seminars.map',
                child: CanadaEventMap(
                  events: events,
                  area: area,
                  expandToFill: true,
                  onOpen: (event) {
                    if (event.informationUrl.isNotEmpty) {
                      _openUrl(event.informationUrl);
                    } else {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => SafeArea(
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * .85,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: _seminar(event),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
  Widget _seminar(LearningSeminar s) {
    final ended = s.status == 'ended' || DateTime.now().isAfter(s.endsAt);
    final canJoin = s.canJoin(DateTime.now());
    final ongoing =
        s.status == 'live' ||
        (!DateTime.now().isBefore(s.startsAt) &&
            DateTime.now().isBefore(s.endsAt));
    return DashboardUi.panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.exampleIndex != null) ...[
            const Chip(label: Text('Example event')),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: LearningExampleCover(index: s.exampleIndex!),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                s.status == 'cancelled'
                    ? 'Cancelled'
                    : ongoing
                    ? (s.mode == 'in_person' ? 'Happening now' : 'Live now')
                    : ended
                    ? 'Finished'
                    : 'Upcoming',
                style: const TextStyle(
                  color: DashboardUi.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (s.organization.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.organization,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: DashboardUi.muted,
              ),
            ),
          ],
          if (s.areaName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${s.kindLabel} · ${s.areaName} · ${s.mode == 'in_person'
                  ? 'In person'
                  : s.mode == 'hybrid'
                  ? 'Hybrid'
                  : 'Online'}',
            ),
          ],
          if (s.venue.isNotEmpty) ...[const SizedBox(height: 8), Text(s.venue)],
          const SizedBox(height: 10),
          Text(
            '${DateFormat('EEE, MMM d • h:mm a').format(s.startsAt)} (${s.startsAt.timeZoneName}) • ${s.duration} min',
            style: const TextStyle(color: DashboardUi.muted),
          ),
          const SizedBox(height: 12),
          Text(s.description, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (s.exampleIndex == null && s.status != 'cancelled' && !ended)
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          if (await _signedIn())
                            _action(
                              () => LearningService.rsvp(s, !s.registered),
                            );
                        },
                  icon: Icon(
                    s.registered ? Icons.check : Icons.event_available,
                  ),
                  label: Text(
                    s.registered ? 'Reserved • cancel' : 'Reserve my place',
                  ),
                ),
              if (s.informationUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openUrl(s.informationUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visit event website'),
                ),
              if (canJoin)
                FilledButton.icon(
                  onPressed: () => _openUrl(s.joinUrl),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join seminar'),
                ),
              if (s.exampleIndex == null && s.status != 'cancelled')
                TextButton.icon(
                  onPressed: () => _calendar(s),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Add to calendar'),
                ),
              if (s.replayUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openUrl(s.replayUrl),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch replay'),
                ),
              if (s.exampleIndex == null &&
                  (permissions.isOwner || s.hostId == BackendService.user?.id))
                PopupMenuButton<String>(
                  tooltip: 'Manage seminar',
                  onSelected: (status) => _action(
                    () => LearningService.seminarStatus(s.id, status),
                  ),
                  itemBuilder: (_) => [
                    for (final status in const ['live', 'ended', 'cancelled'])
                      PopupMenuItem(
                        value: status,
                        child: Text(
                          status == 'live'
                              ? 'Mark live'
                              : status == 'ended'
                              ? 'Mark finished'
                              : 'Cancel session',
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String value) async {
    if (!LearningSeminar.validUrl(value)) return;
    if (!await launchUrl(
          Uri.parse(value),
          mode: LaunchMode.externalApplication,
        ) &&
        mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The link could not open. Please try again.'),
        ),
      );
  }

  Future<void> _calendar(LearningSeminar s) async {
    String date(DateTime d) =>
        DateFormat("yyyyMMdd'T'HHmmss'Z'").format(d.toUtc());
    String escape(String value) => value
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\r', '');
    final ics =
        'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Affinity//Learning//EN\r\nBEGIN:VEVENT\r\nUID:${s.id}@affinity-learning\r\nDTSTAMP:${date(DateTime.now())}\r\nDTSTART:${date(s.startsAt)}\r\nDTEND:${date(s.endsAt)}\r\nSUMMARY:${escape(s.title)}\r\nURL:${s.informationUrl}\r\nDESCRIPTION:${escape(s.description)}\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
    try {
      await FilePicker.platform.saveFile(
        fileName: 'learning-seminar.ics',
        bytes: utf8.encode(ics),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar download failed. Please try again.'),
          ),
        );
    }
  }

  Future<void> _schedule() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const LearningSeminarComposer(),
    );
    if (mounted) refresh();
  }

  Widget _map() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'map',
        'Buying & selling, connected',
        'Explore a stage, learn the concepts and check your understanding. Pan or zoom the map, then choose a stage to see what happens next.',
      ),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Buying a business'),
            selected: !seller,
            onSelected: (_) => setState(() {
              seller = false;
              selected = 0;
              answer = null;
            }),
          ),
          ChoiceChip(
            label: const Text('Succession or transfer'),
            selected: seller,
            onSelected: (_) => setState(() {
              seller = true;
              selected = 0;
              answer = null;
            }),
          ),
          Text(
            '${journey.where((p) => completed.contains(p.id)).length} of ${journey.length} stages explored',
            style: const TextStyle(color: DashboardUi.muted),
          ),
        ],
      ),
      const SizedBox(height: 22),
      NovaTarget(
        id: 'learning-map.canvas',
        child: DashboardUi.panel(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 380,
            child: InteractiveViewer(
              minScale: .6,
              maxScale: 2.4,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: SizedBox(
                width: 1060,
                height: 350,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: LearningMapLines()),
                    ),
                    for (var i = 0; i < journey.length; i++)
                      Positioned(
                        left: _node(i).dx,
                        top: _node(i).dy,
                        width: 205,
                        height: 80,
                        child: Semantics(
                          button: true,
                          selected: selected == i,
                          label: journey[i].title,
                          child: Material(
                            color: selected == i
                                ? DashboardUi.blue
                                : completed.contains(journey[i].id)
                                ? DashboardUi.paleGreen
                                : DashboardUi.paleBlue,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              key: Key('learning-map-${journey[i].id}'),
                              onTap: () => setState(() {
                                selected = i;
                                answer = null;
                              }),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: selected == i
                                            ? Colors.white
                                            : DashboardUi.blue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        journey[i].title,
                                        style: TextStyle(
                                          color: selected == i
                                              ? Colors.white
                                              : DashboardUi.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (completed.contains(journey[i].id))
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: selected == i
                                            ? Colors.white
                                            : Colors.green,
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
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      NovaTarget(
        id: 'learning-map.concept',
        child: DashboardUi.panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy(
                'learning.map.${phase.id}.title',
                phase.title,
                size: 24,
                weight: FontWeight.w800,
              ),
              const SizedBox(height: 14),
              copy(
                'learning.map.${phase.id}.explanation',
                phase.explanation,
                size: 16,
              ),
              const SizedBox(height: 18),
              copy(
                'learning.map.why',
                'Why it matters',
                weight: FontWeight.w700,
              ),
              copy('learning.map.${phase.id}.why', phase.why),
              const SizedBox(height: 18),
              copy(
                'learning.map.action',
                'What happens next',
                weight: FontWeight.w700,
              ),
              copy('learning.map.${phase.id}.action', phase.action),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final doc in phase.documents)
                    ActionChip(label: Text(doc), onPressed: _documents),
                ],
              ),
              const Divider(height: 40),
              copy(
                'learning.map.check',
                'Check your understanding',
                size: 19,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              copy('learning.map.${phase.id}.question', phase.question),
              const SizedBox(height: 12),
              for (var i = 0; i < phase.choices.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => setState(() => answer = i),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: answer == i
                          ? DashboardUi.paleBlue
                          : null,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(phase.choices[i]),
                  ),
                ),
              if (answer != null) ...[
                const SizedBox(height: 10),
                Text(
                  answer == phase.correct
                      ? 'That’s right.'
                      : 'Try another answer.',
                  style: TextStyle(
                    color: answer == phase.correct
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (answer == phase.correct)
                  copy('learning.map.${phase.id}.feedback', phase.feedback),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed:
                        answer == phase.correct || completed.contains(phase.id)
                        ? _mark
                        : null,
                    icon: Icon(
                      completed.contains(phase.id)
                          ? Icons.check_circle
                          : Icons.check,
                    ),
                    label: Text(
                      completed.contains(phase.id)
                          ? 'Understood • unmark'
                          : 'Mark this stage understood',
                    ),
                  ),
                  if (selected < journey.length - 1)
                    TextButton(
                      onPressed: () => setState(() {
                        selected++;
                        answer = null;
                      }),
                      child: const Text('Next stage'),
                    ),
                ],
              ),
              if (progressNotice != null) ...[
                const SizedBox(height: 12),
                Text(
                  progressNotice!,
                  style: const TextStyle(color: DashboardUi.muted),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      copy(
        'learning.map.notice',
        'These guides explain the process. Your actual agreement, circumstances and advisers determine the requirements for a transaction.',
        color: DashboardUi.muted,
      ),
      const SizedBox(height: 18),
      TextButton.icon(
        onPressed: () {
          AppTunnelController.select(AppTunnel.buyer);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const DealRoomsPage(initialSide: PlatformSide.business),
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward),
        label: copy(
          'learning.map.real',
          'Ready for a real deal? Open the buyer dashboard',
        ),
      ),
    ],
  );
  Widget _contributors() => permissions.isOwner
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading(
              'approvals',
              'Contributor approvals',
              'Only you can approve publishing access. People must register and verify their email before you approve them.',
            ),
            FilledButton.icon(
              onPressed: () => _approveDialog(),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Approve a contributor'),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: LearningService.publishers(),
              builder: (c, s) {
                if (s.hasError)
                  return _error('Contributor approvals could not load.');
                if (!s.hasData) return const CircularProgressIndicator();
                return Column(
                  children: [
                    for (final p in s.data!)
                      DashboardUi.panel(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(p['display_name']),
                          subtitle: Text(p['email']),
                          trailing: TextButton(
                            onPressed: busy
                                ? null
                                : () => _action(
                                    () => LearningService.approve(
                                      p['email'],
                                      p['display_name'],
                                      p['active'] != true,
                                    ),
                                  ),
                            child: Text(
                              p['active'] == true
                                  ? 'Revoke publishing'
                                  : 'Approve publishing',
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        )
      : _error('Creator access is required for contributor approvals.');
  Future<void> _approveDialog() async {
    final email = TextEditingController(), name = TextEditingController();
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Approve a learning contributor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Registered email'),
            ),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Public contributor name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Approve publishing'),
          ),
        ],
      ),
    );
    if (yes == true && mounted)
      await _action(() => LearningService.approve(email.text, name.text, true));
    email.dispose();
    name.dispose();
  }
}

Offset _node(int i) =>
    Offset((28 + (i < 4 ? i : 7 - i) * 255).toDouble(), i < 4 ? 35 : 225);

class LearningMapLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFACBCD3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 7; i++) {
      final a = _node(i) + const Offset(102, 40),
          b = _node(i + 1) + const Offset(102, 40);
      canvas.drawLine(a, b, paint);
    } // Screening and financing can run in parallel with diligence.
    final a = _node(3) + const Offset(102, 40),
        b = _node(5) + const Offset(102, 40);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(1060, 180, b.dx, b.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LearningGallery extends StatefulWidget {
  const LearningGallery({super.key, required this.media});
  final List<LearningAttachment> media;
  @override
  State<LearningGallery> createState() => _LearningGalleryState();
}

class _LearningGalleryState extends State<LearningGallery> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    final file = widget.media[current.clamp(0, widget.media.length - 1)];
    return Column(
      children: [
        if (file.image)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              file.url,
              height: MediaQuery.sizeOf(context).width < 600 ? 260 : 460,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'This image could not load. Refresh or open the attachment.',
                ),
              ),
            ),
          )
        else if (file.video || file.audio)
          LearningMediaPlayer(
            key: ValueKey(file.path),
            url: file.url,
            audio: file.audio,
          )
        else
          const Padding(
            padding: EdgeInsets.all(30),
            child: Icon(
              Icons.description_outlined,
              size: 60,
              color: DashboardUi.blue,
            ),
          ),
        Row(
          children: [
            if (widget.media.length > 1)
              IconButton(
                tooltip: 'Previous attachment',
                onPressed: current > 0 ? () => setState(() => current--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
            Expanded(child: Text(file.name, overflow: TextOverflow.ellipsis)),
            Text('${current + 1}/${widget.media.length}'),
            if (widget.media.length > 1)
              IconButton(
                tooltip: 'Next attachment',
                onPressed: current < widget.media.length - 1
                    ? () => setState(() => current++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(file.url),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Open file'),
            ),
          ],
        ),
        if (file.video)
          const Text(
            'Playback depends on your browser and the video codec. Use Open file if it cannot play.',
            style: TextStyle(fontSize: 12, color: DashboardUi.muted),
          ),
      ],
    );
  }
}

class LearningPostComposer extends StatefulWidget {
  const LearningPostComposer({super.key, this.initialArea});
  final LearningArea? initialArea;
  @override
  State<LearningPostComposer> createState() => _LearningPostComposerState();
}

class _LearningPostComposerState extends State<LearningPostComposer> {
  final title = TextEditingController(), body = TextEditingController();
  String topic = 'both';
  LearningArea? area;
  @override
  void initState() {
    super.initState();
    area = widget.initialArea;
  }

  final files = <LearningUpload>[];
  bool busy = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: LearningUpload.types.keys.toList(),
      );
      if (result == null || !mounted) return;
      final chosen = result.files
          .map((f) => LearningUpload(f.name, f.bytes ?? Uint8List(0)))
          .toList();
      for (final f in chosen) f.validate();
      if (files.length + chosen.length > 10)
        throw StateError('Add up to 10 attachments.');
      setState(() => files.addAll(chosen));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create a learning post'),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final value = await chooseLearningArea(context);
                      if (value != null && mounted)
                        setState(() => area = value);
                    },
              icon: const Icon(Icons.location_on_outlined),
              label: Text(area?.name ?? 'Choose the post community'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Post title',
                hintText: 'Example: Understanding working capital',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              maxLength: 12000,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Lesson or caption',
                hintText: 'Explain the concept in your own words…',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: topic,
              decoration: const InputDecoration(labelText: 'Topic'),
              items: [
                for (final t in const [
                  'both',
                  'buyer',
                  'seller',
                  'finance',
                  'legal',
                ])
                  DropdownMenuItem(
                    value: t,
                    child: Text(t == 'both' ? 'Buying & selling' : t),
                  ),
              ],
              onChanged: (t) => topic = t!,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: busy ? null : pick,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add photos, video, audio or PDF'),
            ),
            const SizedBox(height: 10),
            const Text(
              'JPG, PNG, WebP, GIF, MP4, WebM, MOV, MP3, WAV, M4A and PDF. Up to 10 files, 90 MB each.',
              style: TextStyle(fontSize: 12, color: DashboardUi.muted),
            ),
            for (var i = 0; i < files.length; i++)
              ListTile(
                title: Text(files[i].name),
                trailing: IconButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => files.removeAt(i)),
                  icon: const Icon(Icons.close),
                ),
              ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  await LearningService.publish(
                    title.text,
                    body.text,
                    topic,
                    files,
                    area: area,
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) setState(() => error = '$e');
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
        child: Text(busy ? 'Publishing…' : 'Publish lesson'),
      ),
    ],
  );
}

class LearningSeminarComposer extends StatefulWidget {
  const LearningSeminarComposer({super.key});
  @override
  State<LearningSeminarComposer> createState() =>
      _LearningSeminarComposerState();
}

class _LearningSeminarComposerState extends State<LearningSeminarComposer> {
  final title = TextEditingController(),
      description = TextEditingController(),
      url = TextEditingController(),
      website = TextEditingController(),
      replay = TextEditingController(),
      organization = TextEditingController(),
      venue = TextEditingController();
  LearningArea? eventArea;
  LearningUpload? eventImage;
  String eventKind = 'seminar', eventMode = 'online';
  String? draftId;
  DateTime start = DateTime.now().add(const Duration(days: 1));
  int duration = 60;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    url.dispose();
    replay.dispose();
    website.dispose();
    organization.dispose();
    venue.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || !mounted) return;
      final file = result.files.single;
      final image = LearningUpload(file.name, file.bytes ?? Uint8List(0));
      image.validate();
      if (image.bytes.length > 5 * 1024 * 1024)
        throw StateError('Choose a picture up to 5 MB.');
      setState(() => eventImage = image);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Use a JPG, PNG or WebP picture up to 5 MB.');
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time != null && mounted)
      setState(
        () => start = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create a community event'),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final value = await chooseLearningArea(context);
                      if (value != null && mounted)
                        setState(() => eventArea = value);
                    },
              icon: const Icon(Icons.location_on_outlined),
              label: Text(eventArea?.name ?? 'Choose the event town'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: organization,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Hosting organization',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: eventKind,
              decoration: const InputDecoration(labelText: 'Event type'),
              items: [
                for (final kind in const [
                  'seminar',
                  'meeting',
                  'information',
                  'workshop',
                ])
                  DropdownMenuItem(
                    value: kind,
                    child: Text(switch (kind) {
                      'seminar' => 'Seminar',
                      'meeting' => 'Meeting',
                      'information' => 'Information session',
                      _ => 'Workshop',
                    }),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) => setState(() => eventKind = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: eventMode,
              decoration: const InputDecoration(labelText: 'How people attend'),
              items: const [
                DropdownMenuItem(value: 'online', child: Text('Online')),
                DropdownMenuItem(value: 'in_person', child: Text('In person')),
                DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
              ],
              onChanged: busy
                  ? null
                  : (value) => setState(() => eventMode = value!),
            ),
            if (eventMode != 'online')
              TextField(
                controller: venue,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Public venue / meeting address',
                  hintText: 'Example: Community centre, main hall',
                ),
              ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: busy ? null : pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                eventImage?.name ??
                    'Add event picture (JPG, PNG, WebP • up to 5 MB)',
              ),
            ),
            if (eventImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.memory(
                  eventImage!.bytes,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text(
                    'This picture could not be displayed. Choose another.',
                  ),
                ),
              ),

            TextField(
              controller: title,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Session title'),
            ),
            TextField(
              controller: description,
              minLines: 3,
              maxLines: 6,
              maxLength: 6000,
              decoration: const InputDecoration(
                labelText: 'What learners will cover',
              ),
            ),
            TextField(
              controller: website,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Event or company website',
                hintText: 'https://…',
                helperText: 'Visitors open this website from your map point.',
              ),
            ),
            TextField(
              controller: url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: eventMode == 'in_person'
                    ? 'Meeting link (optional)'
                    : 'Live meeting URL',
                hintText: 'https://…',
              ),
            ),
            TextField(
              controller: replay,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Replay URL (optional)',
                hintText: 'Add a recording link if available',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: busy ? null : pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                '${DateFormat('MMM d, h:mm a').format(start)} ${start.timeZoneName}',
              ),
            ),
            DropdownButtonFormField<int>(
              initialValue: duration,
              decoration: const InputDecoration(labelText: 'Duration'),
              items: [
                for (final m in const [30, 45, 60, 90, 120])
                  DropdownMenuItem(value: m, child: Text('$m minutes')),
              ],
              onChanged: (m) => duration = m!,
            ),
            const SizedBox(height: 14),
            const Text(
              'Use your own webinar or meeting service. Learners will join through this link.',
              style: TextStyle(color: DashboardUi.muted, fontSize: 12),
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                if (eventArea == null ||
                    eventImage == null ||
                    organization.text.trim().isEmpty) {
                  setState(
                    () => error =
                        'Choose the town, add the hosting organization and an event picture.',
                  );
                  return;
                }
                if (eventMode != 'online' && venue.text.trim().isEmpty) {
                  setState(
                    () => error = 'Add the public venue or meeting address.',
                  );
                  return;
                }
                if (title.text.trim().length < 3 ||
                    !LearningSeminar.validUrl(website.text.trim()) ||
                    (eventMode != 'in_person' &&
                        !LearningSeminar.validUrl(url.text.trim())) ||
                    (eventMode == 'in_person' &&
                        url.text.trim().isNotEmpty &&
                        !LearningSeminar.validUrl(url.text.trim())) ||
                    (replay.text.isNotEmpty &&
                        !LearningSeminar.validUrl(replay.text.trim()))) {
                  setState(
                    () => error =
                        'Enter a title, an HTTPS event website and valid meeting/replay links.',
                  );
                  return;
                }
                if (!start.isAfter(DateTime.now())) {
                  setState(() => error = 'Choose a future start time.');
                  return;
                }
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  draftId = await LearningService.schedule({
                    'website_url': website.text.trim(),
                    'organization': organization.text.trim(),
                    'event_kind': eventKind,
                    'event_mode': eventMode,
                    'venue': venue.text.trim(),
                    ...eventArea!.toJson(),
                    'title': title.text.trim(),
                    'description': description.text.trim(),
                    'starts_at': start.toUtc().toIso8601String(),
                    'duration_minutes': duration,
                    'meeting_url': url.text.trim().isEmpty
                        ? null
                        : url.text.trim(),
                    'replay_url': replay.text.trim().isEmpty
                        ? null
                        : replay.text.trim(),
                  }, draftId: draftId);
                  await LearningService.publishEvent(draftId!, eventImage!);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) setState(() => error = '$e');
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
        child: Text(busy ? 'Publishing…' : 'Publish event'),
      ),
    ],
  );
}

class LearningCaption extends StatefulWidget {
  const LearningCaption({super.key, required this.body});
  final String body;
  @override
  State<LearningCaption> createState() => _LearningCaptionState();
}

class _LearningCaptionState extends State<LearningCaption> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (expanded)
        SelectableText(widget.body, style: const TextStyle(height: 1.5))
      else
        Text(
          widget.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(height: 1.5),
        ),
      if (widget.body.length > 160 || widget.body.split('\n').length > 3)
        TextButton(
          onPressed: () => setState(() => expanded = !expanded),
          child: Text(expanded ? 'Less' : 'Read more'),
        ),
    ],
  );
}
