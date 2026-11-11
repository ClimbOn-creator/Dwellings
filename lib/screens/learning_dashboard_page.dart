import '../services/device_location_service.dart';
import '../widgets/learning_lesson_page.dart';
import '../widgets/transaction_room_panel.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/learning_start_search.dart';
import '../widgets/learning_financial_folders.dart';
import '../widgets/learning_evaluate_cover_flow.dart';
import '../widgets/learning_discover_file_box.dart';
import '../widgets/dashboard_header.dart';
import 'deal_comparison_page.dart';
import 'deal_rooms_page.dart';
import 'dart:async';
import '../widgets/canada_event_map.dart';
import '../widgets/learning_example_cover.dart';
import '../services/learning_examples.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show RealtimeChannel, PostgresChangeEvent;
import '../services/backend_service.dart';
import '../services/learning_service.dart';
import '../widgets/dashboard_ui.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/nova_target.dart';
import 'auth_page.dart';
import '../services/learning_area_service.dart';
import '../widgets/learning_area_picker.dart';

enum LearningView {
  firstSteps('First steps', Icons.flag_outlined),
  roadmap('Roadmap', Icons.route_outlined),
  discover('Discover', Icons.explore_outlined),
  search('Search', Icons.search),
  evaluate('Evaluate', Icons.fact_check_outlined),
  financial('Financial', Icons.calculate_outlined),
  room('Documents', Icons.folder_open_outlined),
  dealStructure('Deal Structure', Icons.account_tree_outlined),
  transition('Transition', Icons.swap_horiz),
  faq('FAQ', Icons.help_outline),
  seminars('Seminars', Icons.videocam_outlined),
  resources('Resources', Icons.public),
  quiz('Deal comparison quiz', Icons.compare_arrows);

  const LearningView(this.label, this.icon);

  final String label;
  final IconData icon;
}

class LearningDashboardPage extends StatefulWidget {
  const LearningDashboardPage({
    super.key,
    this.initialView = LearningView.firstSteps,
    this.loadSeminars,
    this.loadPermissions,
    this.locate = DeviceLocationService.locate,
  });
  final LearningView initialView;
  final Future<List<LearningSeminar>> Function()? loadSeminars;
  final Future<LearningPermissions> Function()? loadPermissions;
  final Future<({double latitude, double longitude})> Function() locate;
  @override
  State<LearningDashboardPage> createState() => _LearningDashboardPageState();
}

class _LearningDashboardPageState extends State<LearningDashboardPage> {
  late LearningView view;
  static final _tabs = LearningView.values.where(
    (view) => view != LearningView.quiz,
  );
  static final _cabinetFiles = [
    for (final tab in LearningView.values)
      if (tab.index >= LearningView.roadmap.index &&
          tab.index <= LearningView.faq.index)
        tab.label,
  ];

  Future<List<LearningSeminar>>? _seminarsFuture;
  SeminarMapRegion? _region;
  bool _nearby = false;
  bool _locating = false;
  int _locationRequest = 0;
  String? _nearbyCity;
  String? _locationNotice;
  String? _documentId;
  String? _roadmapStageId;

  Future<void> _showNearby() async {
    if (_region != null) {
      setState(() => _nearby = true);
      return;
    }

    final request = ++_locationRequest;
    setState(() {
      _locating = true;
      _locationNotice = null;
    });
    try {
      final position = await widget.locate();
      final region = SeminarMapRegion(position.latitude, position.longitude);
      final map = await CanadaMapGeometry.asset;
      if (!mounted || request != _locationRequest) return;
      if (!region
          .projectedBounds(map.normalized)
          .overlaps(const Rect.fromLTWH(0, 0, 1, 1))) {
        setState(
          () => _locationNotice =
              'This map covers Canada. Showing the full map for your location.',
        );
        return;
      }
      setState(() {
        _region = region;
        _nearby = true;
      });
    } catch (error) {
      if (mounted && request == _locationRequest) {
        final denied =
            error is StateError &&
            error.message.toLowerCase().contains('permission');
        setState(
          () => _locationNotice = denied
              ? 'Location is blocked. Allow it in your browser’s site settings or choose a city.'
              : 'Location is unavailable. Choose a city or browse the full Canada map.',
        );
      }
    } finally {
      if (mounted && request == _locationRequest) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _chooseSeminarCity() async {
    final city = await chooseLearningArea(
      context,
      description: 'Pick a Canadian community to see seminars within 500 km.',
      allowDeviceLocation: false,
    );
    if (!mounted || city == null) return;
    _locationRequest++;
    setState(() {
      _region = SeminarMapRegion(city.latitude, city.longitude);
      _nearbyCity = city.name;
      _nearby = true;
      _locating = false;
      _locationNotice = null;
    });
  }

  Future<List<LearningSeminar>> get seminars =>
      _seminarsFuture ??= (widget.loadSeminars ?? LearningService.seminars)();
  LearningPermissions permissions = const LearningPermissions();
  StreamSubscription? auth;
  Timer? clock;
  RealtimeChannel? eventChanges;
  int eventRevision = 0;
  bool updatingEvents = false;

  bool busy = false;
  @override
  void initState() {
    super.initState();
    view = widget.initialView;
    refresh();
    auth = BackendService.authChanges?.listen((_) {
      if (mounted) {
        setState(() {
          permissions = const LearningPermissions();
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
      if (mounted) _loadPermissions();
      if (mounted && view == LearningView.seminars) {
        _refreshEvents();
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
    _seminarsFuture = null;
    _loadPermissions();
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
  bool get _showingQuiz => view == LearningView.quiz;

  String get guide => switch (view) {
    LearningView.quiz => 'comparison',
    LearningView.room => 'learning-room',
    LearningView.roadmap => 'learning-journey',
    LearningView.seminars => 'learning-seminars',
    LearningView.firstSteps => 'learning-first-steps',
    LearningView.financial => 'learning-financial',
    LearningView.evaluate => 'learning-evaluate',
    LearningView.discover => 'learning-discover',
    LearningView.search => 'learning-search',
    _ => 'learning-dashboard',
  };

  void show(LearningView next) {
    if (view == next) return;
    setState(() => view = next);
  }

  void _openSearchResult(LearningSearchDestination result) {
    setState(() {
      switch (result.section) {
        case LearningSearchSection.roadmap:
          _roadmapStageId = result.id;
          view = LearningView.roadmap;
        case LearningSearchSection.documents:
          _documentId = result.id;
          view = LearningView.room;
        case LearningSearchSection.seminars:
          view = LearningView.seminars;
      }
    });
  }

  void _openQuiz() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'learning-quiz'),
      builder: (_) =>
          const LearningDashboardPage(initialView: LearningView.quiz),
    ),
  );

  void _returnFromQuiz() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LearningDashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = DashboardUi.theme(Theme.of(context));
    return Theme(
      data: base.copyWith(
        colorScheme: const ColorScheme.light(
          primary: learningAccent,
          surface: Colors.white,
          onSurface: learningInk,
        ),
        textTheme: base.textTheme.apply(
          bodyColor: learningInk,
          displayColor: learningInk,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = box.maxWidth < 900;
              final sidebar = !compact && !_showingQuiz;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sidebar) ...[
                    _sidebar(),
                    const VerticalDivider(width: 1, color: learningLine),
                  ],
                  Expanded(
                    child: Column(
                      children: [
                        _header(showTitle: !sidebar),
                        Expanded(child: _workspace(compact)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header({required bool showTitle}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SizedBox(
      height: 58,
      child: Row(
        children: [
          if (showTitle)
            const Expanded(
              child: DashboardHeader(
                label: 'Learning dash',
                contentKey: 'dashboard.header.learning',
              ),
            )
          else
            const Spacer(),
          AppNavigationMenu(
            guidePage: guide,
            dark: false,
            showOrganizer: false,
            showPrivateUpdates: false,
            beforeProfile: IconButton(
              tooltip: _showingQuiz
                  ? 'Back to Learning dashboard'
                  : LearningView.quiz.label,
              onPressed: _showingQuiz ? _returnFromQuiz : _openQuiz,
              icon: Icon(
                _showingQuiz ? Icons.arrow_back : LearningView.quiz.icon,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sidebar() => Material(
    color: learningPaper,
    child: SizedBox(
      width: 216,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                const HomeBrandButton(size: 25, dark: false),
                const SizedBox(width: 12),
                Flexible(
                  child: copy(
                    'dashboard.header.learning',
                    'Learning dash',
                    weight: FontWeight.w700,
                    color: learningInk,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                  child: copy(
                    'learning.nav.workspace',
                    'LEARNING',
                    size: 11,
                    color: learningMuted,
                    weight: FontWeight.w700,
                  ),
                ),
                for (final tab in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      dense: true,
                      minTileHeight: 40,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      selected: view == tab,
                      selectedTileColor: learningSelected,
                      selectedColor: learningInk,
                      iconColor: learningMuted,
                      textColor: learningInk,
                      leading: Icon(tab.icon, size: 18),
                      title: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: view == tab
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => show(tab),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _compactNavigation() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final v in _tabs)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(v.label),
              selected: view == v,
              selectedColor: learningSelected,
              onSelected: (_) => show(v),
            ),
          ),
      ],
    ),
  );

  Widget _workspace(bool compact) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (compact && !_showingQuiz)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: _compactNavigation(),
        ),
      Expanded(
        child: view == LearningView.firstSteps
            ? LearningDiscoverFileBox(
                key: const ValueKey(LearningView.firstSteps),
                cabinet: true,
                fileNames: _cabinetFiles,
                buyerDashboard: (_) =>
                    const DealRoomsPage(openedFromDiscover: true),
                loadEvents: widget.loadSeminars ?? LearningService.seminars,
                openEvent: _openSeminar,
                locate: widget.locate,
              )
            : const {
                LearningView.roadmap,
                LearningView.discover,
                LearningView.search,
              }.contains(view)
            ? LearningLessonPage(
                key: ValueKey(view),
                lesson: LearningLesson.values.byName(view.name),
                onOpen: (destination) =>
                    show(LearningView.values.byName(destination)),
                onSearchResult: _openSearchResult,
                initialStageId: _roadmapStageId,
              )
            : view == LearningView.seminars
            ? Padding(
                padding: EdgeInsets.all(compact ? 8 : 12),
                child: _seminars(),
              )
            : SingleChildScrollView(
                key: ValueKey('learning-workspace-${view.name}-'),
                padding: EdgeInsets.all(compact ? 12 : 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          view == LearningView.roadmap ||
                              view == LearningView.financial ||
                              view == LearningView.evaluate
                          ? double.infinity
                          : 1220,
                    ),
                    child: switch (view) {
                      LearningView.evaluate => LearningEvaluateCoverFlow(
                        onOpenFile: (id) => setState(() {
                          _documentId = id;
                          view = LearningView.room;
                        }),
                      ),
                      LearningView.financial =>
                        const LearningFinancialFolders(),
                      LearningView.room => NovaTarget(
                        id: 'learning-room.documents',
                        child: TransactionRoomPanel(
                          initialDocumentId: _documentId,
                        ),
                      ),
                      LearningView.quiz => const DealComparisonPage(
                        embedded: true,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
      ),
    ],
  );

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
              final region = _nearby ? _region : null;
              final visible = region == null
                  ? events
                  : events.where(region.includes).toList();
              return NovaTarget(
                id: 'learning-seminars.map',
                child: CanadaEventMap(
                  events: visible,
                  region: region,
                  expandToFill: true,
                  locationControls: _locationControls(
                    hasNearbyEvents: visible.isNotEmpty,
                  ),
                  onOpen: _openSeminar,
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
  Widget _locationControls({required bool hasNearbyEvents}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_nearby)
            OutlinedButton.icon(
              onPressed: () => setState(() => _nearby = false),
              icon: const Icon(Icons.public),
              label: const Text('Show full map'),
            )
          else
            OutlinedButton.icon(
              onPressed: _locating ? null : _showNearby,
              icon: const Icon(Icons.my_location),
              label: Text(
                _locating
                    ? 'Finding your location…'
                    : _region == null
                    ? 'Use my location'
                    : 'Show nearby',
              ),
            ),
          TextButton(
            onPressed: _chooseSeminarCity,
            child: const Text('Choose a city'),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        _locationNotice ??
            (_nearby
                ? (hasNearbyEvents
                      ? (_nearbyCity == null
                            ? 'Events within 500 km'
                            : 'Events within 500 km of $_nearbyCity')
                      : 'No upcoming seminars within 500 km.')
                : 'Find events within 500 km. Pact does not save your location.'),
        style: const TextStyle(fontSize: 12),
      ),
    ],
  );

  void _openSeminar(LearningSeminar event) {
    if (event.informationUrl.isNotEmpty) {
      _openUrl(event.informationUrl);
      return;
    }
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
        'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Pact//Learning//EN\r\nBEGIN:VEVENT\r\nUID:${s.id}@affinity-learning\r\nDTSTAMP:${date(DateTime.now())}\r\nDTSTART:${date(s.startsAt)}\r\nDTEND:${date(s.endsAt)}\r\nSUMMARY:${escape(s.title)}\r\nURL:${s.informationUrl}\r\nDESCRIPTION:${escape(s.description)}\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
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
