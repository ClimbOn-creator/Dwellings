import '../services/deal_intake_fields.dart';
import '../widgets/deal_intake_form.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/site_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/deal_room_service.dart';
import '../services/member_deal_marketplace_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/topo_background.dart';
import '../widgets/profile_photo.dart';
import '../widgets/app_navigation_menu.dart';
import 'acquisition_support_page.dart';
import 'business_acquisition_page.dart';
import 'auth_page.dart';

const _ink = Color(0xFF171717);
const _paper = Color(0xFFF4F1EB);
const _purple = Color(0xFF053827);
const _lilac = Color(0xFF64645F);
const _surface = Color(0xFFFCFBF8);
const _line = Color(0xFFD6D1C9);

class DealRoomsPage extends StatefulWidget {
  const DealRoomsPage({
    super.key,
    this.initialSide = PlatformSide.property,
    this.startIntake = false,
  });

  final PlatformSide initialSide;
  final bool startIntake;

  @override
  State<DealRoomsPage> createState() => _DealRoomsPageState();
}

class _DealRoomsPageState extends State<DealRoomsPage> {
  late Future<List<DealRoom>> _rooms;
  late PlatformSide _side;
  bool _creating = false;
  bool _showAll = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    _rooms = DealRoomService.loadRooms();
    if (widget.startIntake)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _manualCreate();
      });
  }

  void _refresh() => setState(() => _rooms = DealRoomService.loadRooms());

  void _goStep(int step) {
    if (step == 3) return;
    final page = switch (step) {
      0 => const AcquisitionBlueprintPage(),
      1 => const BuyerReadinessPage(),
      _ => const BusinessAcquisitionPage(),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  DealIntakeDetails? _pendingIntake;

  Future<void> _manualCreate() async {
    final result = await showDialog<DealIntakeDetails>(
      context: context,
      builder: (_) => DealIntakeDialog(
        initialDetails: _pendingIntake,
        initialKind: _side == PlatformSide.business
            ? 'business'
            : 'residential',
      ),
    );
    if (result == null) return;
    _pendingIntake = result;
    if (!mounted) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() => _creating = true);
    try {
      final room = await DealRoomService.createManualRoom(
        title: result.title,
        dealKind: result.kind,
        location: result.location,
        purchasePrice: result.purchasePrice,
        goals: result.goals,
        targetCloseDate: result.targetCloseDate,
        profileSnapshot: result.profileSnapshot,
      );
      if (!mounted) return;
      _pendingIntake = null;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => DealRoomPage(room: room)));
      final foundation = await AcquisitionFoundation.load();
      await foundation.saveForAccount('pipeline');
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              templateValues: {'value1': '${error}'},
              contentKey: 'copy.deal_rooms_page.m1',
              literal: false,
              "Could not create deal: {{value1}}",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _create() async {
    if (_side == PlatformSide.business) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BusinessAcquisitionPage(),
        ),
      );
      _refresh();
      return;
    }
    setState(() => _creating = true);
    try {
      final room = await DealRoomService.createFromLatestAnalysis();
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => DealRoomPage(room: room)));
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              contentKey: 'copy.deal_rooms_page.m2',
              literal: false,
              '$error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: const ColorScheme.light(
          primary: _purple,
          surface: _surface,
        ),
        textTheme: base.textTheme.apply(bodyColor: _ink, displayColor: _ink),
      ),
      child: Scaffold(
        backgroundColor: _paper,
        appBar: AppBar(
          toolbarHeight: 72,
          backgroundColor: const Color(0xFFF7F5F0),
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          title: MediaQuery.sizeOf(context).width < 700
              ? const HomeBrandButton(size: 48, dark: false)
              : const Row(
                  children: [
                    HomeBrandButton(size: 48, dark: false),
                    SizedBox(width: 18),
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m3',
                      literal: true,
                      'DEAL OS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
          actions: [
            if (MediaQuery.sizeOf(context).width >= 700)
              FilledButton.icon(
                onPressed: _creating ? null : _manualCreate,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: SiteText(
                  contentKey: 'copy.deal_rooms_page.m4',
                  literal: false,
                  _creating ? 'CREATING…' : 'NEW DEAL',
                ),
              ),
            const SizedBox(width: 8),
            const AppNavigationMenu(side: PlatformSide.business, dark: false),
            const SizedBox(width: 12),
          ],
        ),
        body: FutureBuilder<List<DealRoom>>(
          future: _rooms,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SiteCopyText(
                        'buyer.load.error',
                        'Could not load your saved deals. Please try again.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _refresh,
                        child: const SiteCopyText('buyer.load.retry', 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allRooms = snapshot.data!
                .where((room) => room.isBusiness)
                .toList();
            return LayoutBuilder(
              builder: (context, box) {
                final desktop = box.maxWidth >= 980;
                return desktop
                    ? Row(
                        children: [
                          _commandCentreRail(),
                          const VerticalDivider(width: 1, color: _line),
                          Expanded(child: _commandCentre(allRooms)),
                          const VerticalDivider(width: 1, color: _line),
                          SizedBox(
                            width: 320,
                            child: _dealIntelligence(allRooms),
                          ),
                        ],
                      )
                    : _mobileCommandCentre(allRooms);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _commandCentreRail() => Container(
    width: 78,
    color: const Color(0xFFF8F6F1),
    padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
    child: Column(
      children: [
        _pipelineRailButton(
          Icons.space_dashboard_outlined,
          'Command centre',
          !_showArchived,
        ),
        _pipelineRailButton(
          Icons.inventory_2_outlined,
          'Archive',
          _showArchived,
          onTap: () => setState(() => _showArchived = true),
        ),
        _pipelineRailButton(
          Icons.add_business_outlined,
          'New deal',
          false,
          onTap: _manualCreate,
        ),
        _pipelineRailButton(
          Icons.calculate_outlined,
          'Deal screen',
          false,
          onTap: _create,
        ),
        const Spacer(),
        _pipelineRailButton(
          Icons.refresh_rounded,
          'Refresh',
          false,
          onTap: _refresh,
        ),
      ],
    ),
  );

  Widget _pipelineRailButton(
    IconData icon,
    String label,
    bool selected, {
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ?? () => setState(() => _showArchived = false),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: selected ? _purple : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _purple : _line),
          ),
          child: Icon(icon, color: selected ? Colors.white : _ink, size: 21),
        ),
      ),
    ),
  );

  Widget _commandCentre(List<DealRoom> allRooms) {
    final rooms = allRooms.where((room) {
      final archived =
          room.status == 'archived' ||
          room.status == 'completed' ||
          room.status == 'cancelled';
      return _showArchived ? archived : !archived;
    }).toList();
    final active = allRooms
        .where(
          (room) =>
              room.status != 'archived' &&
              room.status != 'completed' &&
              room.status != 'cancelled',
        )
        .toList();
    final blockers = active.fold<int>(
      0,
      (total, room) => total + room.blockedTaskCount,
    );
    final dueSoon = active
        .where(
          (room) =>
              room.nextDueAt != null &&
              room.nextDueAt!.isBefore(
                DateTime.now().add(const Duration(days: 8)),
              ),
        )
        .length;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 22),
          color: Colors.white.withValues(alpha: .7),
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = box.maxWidth < 720;
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m5',
                    literal: false,
                    _showArchived ? 'DEAL HISTORY' : 'BUYER COMMAND CENTRE',
                    style: const TextStyle(
                      color: _purple,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m6',
                    literal: false,
                    _showArchived
                        ? 'Archived acquisitions'
                        : 'Every acquisition. One operating system.',
                    style: const TextStyle(
                      fontSize: 29,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              );
              final facts = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _commandHeaderFact('${active.length}', 'ACTIVE'),
                  const SizedBox(width: 22),
                  _commandHeaderFact('$blockers', 'BLOCKERS'),
                  const SizedBox(width: 22),
                  _commandHeaderFact('$dueSoon', 'DUE SOON'),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 20), facts],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  facts,
                ],
              );
            },
          ),
        ),
        const Divider(height: 1, color: _line),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SiteCopyText(
                  'buyer.learning.intro',
                  'Learn the acquisition process, then apply it to a real opportunity. Add a business from Affinity, another website, a broker or a direct conversation. Your private deal keeps the facts, evidence gaps and next steps together.',
                  style: TextStyle(color: _ink, height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _creating ? null : _manualCreate,
                      icon: const Icon(Icons.add),
                      label: const SiteCopyText(
                        'buyer.learning.add',
                        'Add a deal from any source',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _attentionStrip(active, blockers, dueSoon),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m7',
                      literal: false,
                      _showArchived ? 'PAST DEALS' : 'LIVE DEALS',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    SiteText(
                      templateValues: {'value1': '${rooms.length}'},
                      contentKey: 'copy.deal_rooms_page.m8',
                      literal: false,
                      "{{value1}} TOTAL",
                      style: const TextStyle(
                        color: _lilac,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rooms.isEmpty)
                  _dashboardEmpty()
                else
                  ...rooms.map(_dashboardDealRow),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _commandHeaderFact(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      SiteText(
        contentKey: 'copy.deal_rooms_page.m9',
        literal: false,
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      SiteText(
        contentKey: 'copy.deal_rooms_page.m10',
        literal: false,
        label,
        style: const TextStyle(
          color: _lilac,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _attentionStrip(
    List<DealRoom> active,
    int blockers,
    int dueSoon,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _purple,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteText(
                contentKey: 'copy.deal_rooms_page.1',
                literal: true,
                'WHAT NEEDS ATTENTION',
                style: TextStyle(
                  color: Color(0xFFB8CEC4),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              SiteText(
                contentKey: 'copy.deal_rooms_page.m11',
                literal: false,
                active.isEmpty
                    ? 'Start your first private acquisition workspace.'
                    : blockers > 0
                    ? '$blockers blocked task${blockers == 1 ? '' : 's'} need a decision.'
                    : dueSoon > 0
                    ? '$dueSoon deal${dueSoon == 1 ? '' : 's'} have work due this week.'
                    : 'Your active deals are moving without recorded blockers.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: active.isEmpty
              ? _manualCreate
              : () => _openRoom(active.first),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _purple,
          ),
          child: SiteText(
            contentKey: 'copy.deal_rooms_page.m12',
            literal: false,
            active.isEmpty ? 'START A DEAL' : 'OPEN NEXT DEAL',
          ),
        ),
      ],
    ),
  );

  Widget _dashboardDealRow(DealRoom room) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openRoom(room),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EEE9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_outlined, color: _purple),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m13',
                      literal: false,
                      room.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m14',
                      literal: false,
                      '${room.city.isEmpty ? 'Location private' : room.city} · ${room.currentStage.toUpperCase()}',
                      style: const TextStyle(color: _lilac, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m15',
                      literal: false,
                      room.purchasePrice <= 0
                          ? 'Price pending'
                          : NumberFormat.compactCurrency(
                              symbol: '${room.currency} ',
                            ).format(room.purchasePrice),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SiteText(
                      contentKey: 'copy.deal_rooms_page.2',
                      literal: true,
                      'PURCHASE PRICE',
                      style: TextStyle(
                        color: _lilac,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: room.progress,
                        minHeight: 6,
                        color: _purple,
                        backgroundColor: const Color(0xFFE8E5DE),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SiteText(
                      templateValues: {
                        'value1': '${(room.progress * 100).round()}',
                      },
                      contentKey: 'copy.deal_rooms_page.m16',
                      literal: false,
                      "{{value1}}% COMPLETE",
                      style: const TextStyle(
                        color: _lilac,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (room.blockedTaskCount > 0)
                Badge(
                  label: SiteText(
                    contentKey: 'copy.deal_rooms_page.m17',
                    literal: false,
                    '${room.blockedTaskCount}',
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF9D3A32),
                  ),
                )
              else
                const Icon(Icons.arrow_forward_rounded, color: _purple),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _openRoom(DealRoom room) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => DealRoomPage(room: room)));
    _refresh();
  }

  Widget _dashboardEmpty() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(Icons.add_business_outlined, size: 42, color: _purple),
        const SizedBox(height: 14),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m18',
          literal: false,
          _showArchived ? 'No archived deals' : 'Build your first Deal Room',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m19',
          literal: false,
          _showArchived
              ? 'Completed and archived acquisitions will remain available here.'
              : 'Start with what you know. Unknown information can be added later.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _lilac),
        ),
        if (!_showArchived) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _manualCreate,
            icon: const Icon(Icons.add),
            label: const SiteText(
              contentKey: 'copy.deal_rooms_page.3',
              literal: true,
              'NEW DEAL',
            ),
          ),
        ],
      ],
    ),
  );

  Widget _dealIntelligence(List<DealRoom> rooms) {
    final active = rooms
        .where(
          (room) =>
              room.status != 'archived' &&
              room.status != 'completed' &&
              room.status != 'cancelled',
        )
        .toList();
    final next = active.isEmpty ? null : active.first;
    return Container(
      color: const Color(0xFFF8F6F1),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE5EEE9),
                  child: Icon(
                    Icons.insights_outlined,
                    color: _purple,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m20',
                  literal: true,
                  'Deal intelligence',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _sideInsight(
                  'PORTFOLIO',
                  active.isEmpty
                      ? 'No active acquisitions yet.'
                      : '${active.length} active acquisition${active.length == 1 ? '' : 's'} across your private workspace.',
                ),
                const SizedBox(height: 12),
                _sideInsight(
                  'NEXT ACTION',
                  next?.currentStep ??
                      'Create a deal to begin the guided plan.',
                ),
                const SizedBox(height: 12),
                _sideInsight(
                  'PRIVACY',
                  'Nothing reaches the Member Studio until you submit it and Affinity approves an anonymous brief.',
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _manualCreate,
                  icon: const Icon(Icons.add_business_outlined),
                  label: const SiteText(
                    contentKey: 'copy.deal_rooms_page.4',
                    literal: true,
                    'CREATE ANOTHER DEAL',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideInsight(String label, String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(
          contentKey: 'copy.deal_rooms_page.m21',
          literal: false,
          label,
          style: const TextStyle(
            color: _purple,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m22',
          literal: false,
          text,
          style: const TextStyle(fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );

  Widget _mobileCommandCentre(List<DealRoom> rooms) => _commandCentre(rooms);

  Widget _header() => TopoBackground(
    opacity: .055,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 64),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HomeBrandButton(size: 46),
                    const Spacer(),
                    AppNavigationMenu(side: _side),
                  ],
                ),
                const SizedBox(height: 68),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m23',
                  literal: false,
                  _showAll
                      ? 'CURRENT DEALS'
                      : _side == PlatformSide.business
                      ? 'DEALIQ WORKSPACES'
                      : 'PROPERTYIQ WORKSPACES',
                  style: const TextStyle(
                    color: _lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m24',
                  literal: false,
                  _showAll
                      ? 'Every acquisition.\nOne command centre.'
                      : _side == PlatformSide.business
                      ? 'Every acquisition.\nOne working team.'
                      : 'Every property.\nOne working team.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.sizeOf(context).width < 700 ? 48 : 68,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 650,
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m25',
                    literal: false,
                    _showAll
                        ? 'Start, organize and finish residential, commercial and business acquisitions with clear stages, owners, deadlines and blockers.'
                        : 'Turn an assessment into a private workspace for decisions, diligence, financing, legal work and closing.',
                    style: TextStyle(
                      color: Color(0xFFC5C5D0),
                      height: 1.55,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _creating ? null : _manualCreate,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                      ),
                      icon: _creating
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: SiteText(
                        contentKey: 'copy.deal_rooms_page.m26',
                        literal: false,
                        _creating ? 'CREATING…' : 'START A NEW DEAL',
                      ),
                    ),
                    if (_side == PlatformSide.property)
                      OutlinedButton.icon(
                        onPressed: _creating ? null : _create,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                        icon: const Icon(Icons.auto_graph, size: 18),
                        label: const SiteText(
                          contentKey: 'copy.deal_rooms_page.5',
                          literal: true,
                          'USE LATEST ANALYSIS',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const SiteText(
                        contentKey: 'copy.deal_rooms_page.6',
                        literal: true,
                        'ALL DEALS',
                      ),
                      selected: _showAll,
                      onSelected: (_) => setState(() => _showAll = true),
                    ),
                    ChoiceChip(
                      label: SiteText(
                        contentKey: 'copy.deal_rooms_page.m27',
                        literal: false,
                        _showArchived ? 'PAST / ARCHIVED' : 'CURRENT',
                      ),
                      selected: _showArchived,
                      onSelected: (value) =>
                          setState(() => _showArchived = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _empty() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      color: _surface,
      border: const Border(
        top: BorderSide(color: Color(0xFF244E43), width: 5),
        bottom: BorderSide(color: _line),
      ),
    ),
    child: Column(
      children: [
        const Icon(Icons.meeting_room_outlined, size: 44, color: _purple),
        const SizedBox(height: 15),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m28',
          literal: false,
          _showArchived ? 'No past deals yet' : 'No current deals yet',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m29',
          literal: false,
          _showArchived
              ? 'Completed, cancelled and archived transactions will remain available here.'
              : 'Start a business acquisition and its guided checklist will be created automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFA5A5B5)),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _creating ? null : _manualCreate,
          child: const SiteText(
            contentKey: 'copy.deal_rooms_page.7',
            literal: true,
            'START A NEW DEAL',
          ),
        ),
      ],
    ),
  );

  Widget _summary(List<DealRoom> rooms) {
    final active = rooms
        .where(
          (room) =>
              room.status != 'completed' &&
              room.status != 'cancelled' &&
              room.status != 'archived',
        )
        .toList();
    final blocked = active.fold<int>(
      0,
      (total, room) => total + room.blockedTaskCount,
    );
    final now = DateTime.now();
    final dueSoon = active.where((room) {
      final due = room.nextDueAt;
      return due != null && due.isBefore(now.add(const Duration(days: 8)));
    }).length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryMetric('${active.length}', 'ACTIVE DEALS', Icons.track_changes),
        _summaryMetric('$blocked', 'BLOCKED TASKS', Icons.warning_amber),
        _summaryMetric('$dueSoon', 'DUE IN 7 DAYS', Icons.event_outlined),
      ],
    );
  }

  Widget _summaryMetric(String value, String label, IconData icon) => Container(
    width: 210,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      border: const Border(
        top: BorderSide(color: Color(0xFF244E43), width: 3),
        bottom: BorderSide(color: _line),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: _purple, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SiteText(
              contentKey: 'copy.deal_rooms_page.m30',
              literal: false,
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SiteText(
              contentKey: 'copy.deal_rooms_page.m31',
              literal: false,
              label,
              style: const TextStyle(
                color: Color(0xFF777785),
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _roomCard(DealRoom room) => InkWell(
    onTap: () async {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => DealRoomPage(room: room)));
      _refresh();
    },
    child: Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(color: Color(0xFFE8ECE8)),
            child: Icon(
              room.isBusiness ? Icons.storefront_outlined : Icons.apartment,
              color: _purple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m32',
                      literal: false,
                      room.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _status(room.status),
                    _status(room.dealKind),
                    if (!room.ownedByCurrentUser) _status('shared'),
                  ],
                ),
                const SizedBox(height: 7),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m33',
                  literal: false,
                  [
                    if (room.city.isNotEmpty) room.city,
                    if (room.purchasePrice > 0)
                      NumberFormat.simpleCurrency(
                        name: room.currency,
                        decimalDigits: 0,
                      ).format(room.purchasePrice),
                    'Updated ${DateFormat.MMMd().format(room.updatedAt)}',
                    if (room.targetCloseDate != null)
                      'Target ${DateFormat.MMMd().format(room.targetCloseDate!)}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: Color(0xFF575764),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: room.progress,
                          backgroundColor: _line,
                          valueColor: const AlwaysStoppedAnimation(_purple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m34',
                      literal: false,
                      '${room.completedTaskCount}/${room.totalTaskCount}',
                      style: const TextStyle(
                        color: _purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m35',
                  literal: false,
                  '${room.currentStage.toUpperCase()} · ${room.currentStep.toUpperCase()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .45,
                  ),
                ),
                if (room.blockedTaskCount > 0) ...[
                  const SizedBox(height: 7),
                  SiteText(
                    templateValues: {
                      'value1': '${room.blockedTaskCount}',
                      'value2': '${room.blockedTaskCount == 1 ? '' : 'S'}',
                    },
                    contentKey: 'copy.deal_rooms_page.m36',
                    literal: false,
                    "{{value1}} BLOCKER{{value2}} NEED ATTENTION",
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: _purple),
        ],
      ),
    ),
  );

  Widget _status(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: _purple.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: SiteText(
      contentKey: 'copy.deal_rooms_page.m37',
      literal: false,
      value.toUpperCase().replaceAll('_', ' '),
      style: const TextStyle(
        color: _purple,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class DealIntakeDetails {
  const DealIntakeDetails({
    required this.title,
    required this.kind,
    required this.location,
    required this.purchasePrice,
    required this.goals,
    required this.targetCloseDate,
    required this.profileSnapshot,
  });
  final String title;
  final String kind;
  final String location;
  final double purchasePrice;
  final String goals;
  final DateTime? targetCloseDate;
  final Map<String, dynamic> profileSnapshot;
}

class DealIntakeDialog extends StatefulWidget {
  const DealIntakeDialog({
    super.key,
    required this.initialKind,
    this.initialDetails,
  });
  final DealIntakeDetails? initialDetails;
  final String initialKind;

  @override
  State<DealIntakeDialog> createState() => DealIntakeDialogState();
}

class DealIntakeDialogState extends State<DealIntakeDialog> {
  final _extra = {
    for (final f in dealIntakeFields) f.key: TextEditingController(),
  };
  String? _validationError;
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _goals = TextEditingController();
  final _revenue = TextEditingController();
  final _ebitda = TextEditingController();
  final _availableCapital = TextEditingController();
  late String _kind;
  String _industry = 'Business services';
  int _step = 0;
  bool _financingNeeded = true;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    final draft = widget.initialDetails;
    if (draft != null) {
      final snapshot = draft.profileSnapshot;
      _kind = draft.kind;
      _title.text = draft.title;
      _details.text = snapshot['deal_details'] as String? ?? '';
      _location.text = draft.location;
      _price.text = draft.purchasePrice == 0 ? '' : '${draft.purchasePrice}';
      _goals.text = draft.goals;
      _targetDate = draft.targetCloseDate;
      _industry = snapshot['industry'] as String? ?? _industry;
      _financingNeeded = snapshot['financing_needed'] as bool? ?? true;
      _revenue.text = '${snapshot['annual_revenue'] ?? ''}';
      _ebitda.text = '${snapshot['reported_ebitda'] ?? ''}';
      _availableCapital.text = '${snapshot['available_capital'] ?? ''}';
      for (final entry in _extra.entries) {
        entry.value.text = '${snapshot[entry.key] ?? ''}';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _extra.values) {
      c.dispose();
    }
    _title.dispose();
    _details.dispose();
    _location.dispose();
    _price.dispose();
    _goals.dispose();
    _revenue.dispose();
    _ebitda.dispose();
    _availableCapital.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 60)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _targetDate = date);
  }

  void _submit() {
    final extra = {for (final e in _extra.entries) e.key: e.value.text.trim()};
    final error = validateDealIntake(extra, [
      _price.text,
      _revenue.text,
      _ebitda.text,
      _availableCapital.text,
    ]);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    if (_title.text.trim().isEmpty || _details.text.trim().length < 40) return;
    Navigator.pop(
      context,
      DealIntakeDetails(
        title: _title.text.trim(),
        kind: _kind,
        location: _location.text.trim(),
        purchasePrice:
            double.tryParse(_price.text.replaceAll(',', '').trim()) ?? 0,
        goals: _goals.text.trim(),
        targetCloseDate: _targetDate,
        profileSnapshot: {
          'industry': _industry,
          'deal_details': _details.text.trim(),
          'annual_revenue': _money(_revenue.text),
          'reported_ebitda': _money(_ebitda.text),
          'available_capital': _money(_availableCapital.text),
          'financing_needed': _financingNeeded,
          ...extra,
          'currency': extra['currency']!.toUpperCase(),
          'wizard_version': 2,
        },
      ),
    );
  }

  double? _money(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    return cleaned.isEmpty ? null : double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: _surface,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 940, maxHeight: 680),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 14, 18),
            decoration: const BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_business_outlined, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SiteText(
                        contentKey: 'copy.deal_rooms_page.m38',
                        literal: true,
                        'NEW PRIVATE DEAL',
                        style: TextStyle(
                          color: Color(0xFFB8CEC4),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      SiteText(
                        contentKey: 'copy.deal_rooms_page.m39',
                        literal: true,
                        'Start with what you know',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final desktop = box.maxWidth >= 720;
                return Row(
                  children: [
                    if (desktop) SizedBox(width: 220, child: _wizardRail()),
                    if (desktop) const VerticalDivider(width: 1, color: _line),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(26),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _wizardStep(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: _line),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const SiteText(
                      contentKey: 'copy.deal_rooms_page.8',
                      literal: true,
                      'BACK',
                    ),
                  ),
                SiteText(
                  templateValues: {'value1': '${_step + 1}'},
                  contentKey: 'copy.deal_rooms_page.m40',
                  literal: false,
                  "{{value1}} OF 4",
                  style: const TextStyle(
                    color: _lilac,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                FilledButton(
                  onPressed: _step == 3
                      ? (_title.text.trim().isEmpty ||
                                _details.text.trim().length < 40
                            ? null
                            : _submit)
                      : () => setState(() => _step++),
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m41',
                    literal: false,
                    _step == 3 ? 'CREATE PRIVATE DEAL' : 'CONTINUE',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _wizardRail() => Container(
    color: const Color(0xFFF4F1EB),
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wizardRailItem(0, Icons.storefront_outlined, 'Opportunity'),
        _wizardRailItem(1, Icons.query_stats_outlined, 'What you know'),
        _wizardRailItem(2, Icons.flag_outlined, 'Acquisition plan'),
        _wizardRailItem(3, Icons.fact_check_outlined, 'Review'),
        const Spacer(),
        const SiteText(
          contentKey: 'copy.deal_rooms_page.9',
          literal: true,
          'Unknown values can stay blank and be completed later inside the Deal Room.',
          style: TextStyle(color: _lilac, fontSize: 10, height: 1.45),
        ),
      ],
    ),
  );

  Widget _wizardRailItem(int step, IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: _step == step,
      selectedTileColor: const Color(0xFFE5EEE9),
      leading: Icon(icon, size: 19, color: _step == step ? _purple : _lilac),
      title: SiteText(
        contentKey: 'copy.deal_rooms_page.m42',
        literal: false,
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: _step == step ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      onTap: () => setState(() => _step = step),
    ),
  );

  Widget _wizardStep() => switch (_step) {
    0 => _opportunityStep(),
    1 => _knownStep(),
    2 => _planStep(),
    _ => _reviewStep(),
  };

  Widget _stepIntro(String eyebrow, String title, String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SiteText(
        contentKey: 'copy.deal_rooms_page.m43',
        literal: false,
        eyebrow,
        style: const TextStyle(
          color: _purple,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 7),
      SiteText(
        contentKey: 'copy.deal_rooms_page.m44',
        literal: false,
        title,
        style: const TextStyle(
          fontSize: 28,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 9),
      SiteText(
        contentKey: 'copy.deal_rooms_page.m45',
        literal: false,
        text,
        style: const TextStyle(color: _lilac, height: 1.5),
      ),
      const SizedBox(height: 22),
    ],
  );

  Widget _opportunityStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'STEP 1',
        'The opportunity',
        'Give the workspace a useful identity. Keep seller-sensitive information out of the title.',
      ),
      DealIntakeForm(controllers: _extra, stage: 0),
      TextField(
        controller: _title,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          label: SiteText(
            'Private deal name',
            contentKey: 'copy.deal_rooms_page.field1',
            literal: true,
          ),
          hint: SiteText(
            'Example: Lower Mainland service company',
            contentKey: 'copy.deal_rooms_page.field2',
            literal: true,
          ),
        ),
      ),
      const SizedBox(height: 13),
      DropdownButtonFormField<String>(
        initialValue: _industry,
        isExpanded: true,
        decoration: const InputDecoration(
          label: SiteText(
            'Industry',
            contentKey: 'copy.deal_rooms_page.field3',
            literal: true,
          ),
        ),
        items:
            const [
                  'Business services',
                  'Home services',
                  'Industrial services',
                  'Healthcare',
                  'Technology',
                  'Retail',
                  'Hospitality',
                  'Other',
                ]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: SiteText(
                      contentKey: 'copy.deal_rooms_page.m46',
                      literal: false,
                      value,
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) => setState(() => _industry = value ?? _industry),
      ),
      const SizedBox(height: 13),
      TextField(
        controller: _location,
        decoration: const InputDecoration(
          label: SiteText(
            'City, region, or market',
            contentKey: 'copy.deal_rooms_page.field4',
            literal: true,
          ),
          hint: SiteText(
            'Leave blank if location is not known',
            contentKey: 'copy.deal_rooms_page.field5',
            literal: true,
          ),
        ),
      ),
      const SizedBox(height: 13),
      TextField(
        controller: _details,
        minLines: 3,
        maxLines: 5,
        maxLength: 500,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          label: SiteText(
            'Deal details (required)',
            contentKey: 'copy.deal_rooms_page.field6',
            literal: true,
          ),
          hint: SiteText(
            'In a short paragraph, describe the business, what attracts you to it, and what you are trying to accomplish.',
            contentKey: 'copy.deal_rooms_page.field7',
            literal: true,
          ),
          helperText:
              'Minimum 40 characters. Keep seller-identifying details private.',
        ),
      ),
    ],
  );

  Widget _knownStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'STEP 2',
        'What you know today',
        'These figures are optional. Blank information becomes part of the diligence plan rather than blocking you.',
      ),
      DealIntakeForm(controllers: _extra, stage: 1),
      _moneyField(_price, 'Expected purchase price', 'Unknown is okay'),
      const SizedBox(height: 13),
      _moneyField(
        _revenue,
        'Annual revenue',
        'Use the latest normalized year if available',
      ),
      const SizedBox(height: 13),
      _moneyField(
        _ebitda,
        'Reported EBITDA',
        'Leave blank until earnings are verified',
      ),
    ],
  );

  Widget _moneyField(
    TextEditingController controller,
    String label,
    String hint,
  ) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      label: siteInputCopy(
        label,
        contentKey: 'copy.deal_rooms_page.field.dynamic1',
      ),
      hint: siteInputCopy(
        hint,
        contentKey: 'copy.deal_rooms_page.field.dynamic2',
      ),
      prefixText: '${_extra['currency']!.text.trim().toUpperCase()} ',
    ),
  );

  Widget _planStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'STEP 3',
        'Your acquisition plan',
        'Record the decision context. Affinity will turn this into tasks, evidence requests, and professional needs.',
      ),
      DealIntakeForm(controllers: _extra, stage: 2),
      _moneyField(
        _availableCapital,
        'Capital currently available',
        'Leave blank if financing capacity is not known',
      ),
      const SizedBox(height: 12),
      SwitchListTile(
        value: _financingNeeded,
        contentPadding: EdgeInsets.zero,
        title: const SiteText(
          contentKey: 'copy.deal_rooms_page.10',
          literal: true,
          'Financing support expected',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const SiteText(
          contentKey: 'copy.deal_rooms_page.11',
          literal: true,
          'Helps Affinity identify relevant lenders and capital partners.',
        ),
        onChanged: (value) => setState(() => _financingNeeded = value),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _goals,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          label: SiteText(
            'Goals and decision context',
            contentKey: 'copy.deal_rooms_page.field8',
            literal: true,
          ),
          hint: SiteText(
            'What would make this acquisition successful?',
            contentKey: 'copy.deal_rooms_page.field9',
            literal: true,
          ),
        ),
      ),
      const SizedBox(height: 13),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.event_outlined),
          label: SiteText(
            contentKey: 'copy.deal_rooms_page.m47',
            literal: false,
            _targetDate == null
                ? 'ADD OPTIONAL TARGET CLOSE'
                : 'TARGET ${DateFormat.yMMMd().format(_targetDate!)}',
          ),
        ),
      ),
    ],
  );

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'STEP 4',
        'Create the private workspace',
        'Affinity will create a guided acquisition plan. Nothing is published to members automatically.',
      ),
      _reviewLine(
        'Deal',
        _title.text.trim().isEmpty
            ? 'A private name is required'
            : _title.text.trim(),
      ),
      if (_validationError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            _validationError!,
            style: const TextStyle(color: Color(0xFF9D2018)),
          ),
        ),
      for (final f in dealIntakeFields)
        _reviewLine(
          f.label,
          _extra[f.key]!.text.trim().isEmpty
              ? 'Unknown — follow up'
              : _extra[f.key]!.text.trim(),
        ),
      _reviewLine('Industry', _industry),
      _reviewLine(
        'Deal details',
        _details.text.trim().length < 40
            ? 'A short paragraph is required'
            : _details.text.trim(),
      ),
      _reviewLine(
        'Location',
        _location.text.trim().isEmpty ? 'Not known yet' : _location.text.trim(),
      ),
      _reviewLine(
        'Purchase price',
        _money(_price.text) == null
            ? 'Not known yet'
            : NumberFormat.simpleCurrency(
                name: _extra['currency']!.text.trim().isEmpty
                    ? 'CAD'
                    : _extra['currency']!.text.trim().toUpperCase(),
                decimalDigits: 0,
              ).format(_money(_price.text)),
      ),
      _reviewLine(
        'Revenue',
        _money(_revenue.text) == null
            ? 'Not known yet'
            : NumberFormat.simpleCurrency(
                name: _extra['currency']!.text.trim().isEmpty
                    ? 'CAD'
                    : _extra['currency']!.text.trim().toUpperCase(),
                decimalDigits: 0,
              ).format(_money(_revenue.text)),
      ),
      _reviewLine(
        'Financing',
        _financingNeeded ? 'Support expected' : 'Not currently required',
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EEE9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: SiteText(
          templateValues: {
            'value1': '${DealRoomService.templatesFor(_kind).length}',
            'value2': '${DealRoomService.stagesFor(_kind).length}',
          },
          contentKey: 'copy.deal_rooms_page.m48',
          literal: false,
          "{{value1}} guided actions across {{value2}} acquisition stages will be added automatically.",
          style: const TextStyle(
            color: _purple,
            fontSize: 11,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget _reviewLine(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: SiteText(
            contentKey: 'copy.deal_rooms_page.m49',
            literal: false,
            label.toUpperCase(),
            style: const TextStyle(
              color: _lilac,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: SiteText(
            contentKey: 'copy.deal_rooms_page.m50',
            literal: false,
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _TaskUpdate {
  const _TaskUpdate({
    required this.status,
    required this.blockerNote,
    required this.dueAt,
    required this.assignedProviderId,
  });
  final String status;
  final String blockerNote;
  final DateTime? dueAt;
  final String? assignedProviderId;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({required this.task, required this.members});
  final DealRoomTask task;
  final List<DealRoomMember> members;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late String _status;
  late DateTime? _dueAt;
  late String? _assignedProviderId;
  late final TextEditingController _blocker;

  @override
  void initState() {
    super.initState();
    _status = widget.task.status;
    _dueAt = widget.task.dueAt;
    _assignedProviderId = widget.task.assignedProviderId;
    _blocker = TextEditingController(text: widget.task.blockerNote);
  }

  @override
  void dispose() {
    _blocker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: SiteText(
      contentKey: 'copy.deal_rooms_page.m51',
      literal: false,
      widget.task.title,
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.task.details.isNotEmpty)
              SiteText(
                contentKey: 'copy.deal_rooms_page.m52',
                literal: false,
                widget.task.details,
                style: const TextStyle(color: Color(0xFF666674), height: 1.45),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                label: SiteText(
                  'Task status',
                  contentKey: 'copy.deal_rooms_page.field10',
                  literal: true,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'not_started',
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m53',
                    literal: true,
                    'Not started',
                  ),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m54',
                    literal: true,
                    'In progress',
                  ),
                ),
                DropdownMenuItem(
                  value: 'blocked',
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m55',
                    literal: true,
                    'Blocked',
                  ),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m56',
                    literal: true,
                    'Completed',
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _assignedProviderId,
              decoration: const InputDecoration(
                label: SiteText(
                  'Assigned to',
                  contentKey: 'copy.deal_rooms_page.field11',
                  literal: true,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m57',
                    literal: true,
                    'Unassigned / deal owner',
                  ),
                ),
                ...widget.members.map(
                  (member) => DropdownMenuItem<String?>(
                    value: member.provider.id,
                    child: SiteText(
                      contentKey: 'copy.deal_rooms_page.m58',
                      literal: false,
                      member.provider.name,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _assignedProviderId = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate:
                        _dueAt ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (selected != null) setState(() => _dueAt = selected);
                },
                icon: const Icon(Icons.event_outlined),
                label: SiteText(
                  contentKey: 'copy.deal_rooms_page.m59',
                  literal: false,
                  _dueAt == null
                      ? 'ADD DUE DATE'
                      : 'DUE ${DateFormat.yMMMd().format(_dueAt!)}',
                ),
              ),
            ),
            if (_status == 'blocked') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _blocker,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  label: SiteText(
                    'What is blocking this task?',
                    contentKey: 'copy.deal_rooms_page.field12',
                    literal: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const SiteText(
          contentKey: 'copy.deal_rooms_page.12',
          literal: true,
          'CANCEL',
        ),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _TaskUpdate(
            status: _status,
            blockerNote: _blocker.text,
            dueAt: _dueAt,
            assignedProviderId: _assignedProviderId,
          ),
        ),
        child: const SiteText(
          contentKey: 'copy.deal_rooms_page.13',
          literal: true,
          'SAVE TASK',
        ),
      ),
    ],
  );
}

class DealRoomPage extends StatefulWidget {
  const DealRoomPage({super.key, required this.room});
  final DealRoom room;

  @override
  State<DealRoomPage> createState() => _DealRoomPageState();
}

enum _DealWorkspaceView {
  overview,
  profile,
  financials,
  evaluation,
  plan,
  vault,
  team,
  timeline,
  privacy,
}

class _DealRoomPageState extends State<DealRoomPage> {
  late DealRoom _room;
  late Future<DealRoomBundle> _bundle;
  final _note = TextEditingController();
  final _timeline = TextEditingController();
  final _goals = TextEditingController();
  final _dealTitle = TextEditingController();
  final _extra = {
    for (final f in dealIntakeFields) f.key: TextEditingController(),
  };
  final _dealDetails = TextEditingController();
  final _dealLocation = TextEditingController();
  final _dealPrice = TextEditingController();
  final _dealRevenue = TextEditingController();
  final _dealEbitda = TextEditingController();
  final _dealCapital = TextEditingController();
  DateTime? _targetDate;
  bool _saving = false;
  bool _uploading = false;
  bool _introductionsOpen = true;
  _DealWorkspaceView _workspaceView = _DealWorkspaceView.overview;
  late Future<List<MemberDealPitch>> _introductions;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    for (final e in _extra.entries) {
      e.value.text =
          '${_room.propertySnapshot[e.key] ?? (e.key == "currency" ? "CAD" : "")}';
    }
    _timeline.text = _room.timeline;
    _goals.text = _room.goals;
    _dealTitle.text = _room.title;
    _dealDetails.text = _room.propertySnapshot['deal_details'] as String? ?? '';
    _dealLocation.text = _room.city;
    _dealPrice.text = _room.purchasePrice <= 0
        ? ''
        : _room.purchasePrice.toString();
    _dealRevenue.text = _snapshotNumber('annual_revenue');
    _dealEbitda.text = _snapshotNumber('reported_ebitda');
    _dealCapital.text = _snapshotNumber('available_capital');
    _targetDate = _room.targetCloseDate;
    _bundle = DealRoomService.loadBundle(_room);
    _introductions = MemberDealMarketplaceService.loadBuyerResponses();
  }

  @override
  void dispose() {
    _note.dispose();
    _timeline.dispose();
    _goals.dispose();
    _dealTitle.dispose();
    for (final c in _extra.values) {
      c.dispose();
    }
    _dealDetails.dispose();
    _dealLocation.dispose();
    _dealPrice.dispose();
    _dealRevenue.dispose();
    _dealEbitda.dispose();
    _dealCapital.dispose();
    super.dispose();
  }

  String _snapshotNumber(String key) {
    final value = _room.propertySnapshot[key];
    return value is num ? value.toString() : '';
  }

  void _refresh() => setState(() {
    _bundle = DealRoomService.loadBundle(_room);
    _introductions = MemberDealMarketplaceService.loadBuyerResponses();
  });

  Future<void> _saveRoom(String status, {String? currentStage}) async {
    setState(() => _saving = true);
    try {
      final nextStage = currentStage ?? _room.currentStage;
      await DealRoomService.updateRoom(
        roomId: _room.id,
        status: status,
        timeline: _timeline.text,
        goals: _goals.text,
        currentStage: nextStage,
        targetCloseDate: _targetDate,
      );
      _room = DealRoom(
        id: _room.id,
        userId: _room.userId,
        title: _room.title,
        address: _room.address,
        city: _room.city,
        purchasePrice: _room.purchasePrice,
        timeline: _timeline.text,
        goals: _goals.text,
        status: status,
        propertySnapshot: _room.propertySnapshot,
        riskSnapshot: _room.riskSnapshot,
        sharingPreferences: _room.sharingPreferences,
        updatedAt: DateTime.now(),
        transactionType: _room.transactionType,
        dealKind: _room.dealKind,
        currentStage: nextStage,
        targetCloseDate: _targetDate,
        archivedAt: status == 'archived' ? DateTime.now() : null,
        completedTaskCount: _room.completedTaskCount,
        totalTaskCount: _room.totalTaskCount,
        currentStep: _room.currentStep,
        blockedTaskCount: _room.blockedTaskCount,
        nextDueAt: _room.nextDueAt,
      );
      _refresh();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _fieldNumber(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;

  Future<void> _saveDealProfile() async {
    if (_dealTitle.text.trim().isEmpty) return;
    final extra = {for (final e in _extra.entries) e.key: e.value.text.trim()};
    final error = validateDealIntake(extra, [
      _dealPrice.text,
      _dealRevenue.text,
      _dealEbitda.text,
      _dealCapital.text,
    ], requireCountry: false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);
    try {
      final snapshot = Map<String, dynamic>.from(_room.propertySnapshot)
        ..addAll(extra)
        ..['currency'] = extra['currency']!.toUpperCase()
        ..['deal_details'] = _dealDetails.text.trim()
        ..['annual_revenue'] = (_dealRevenue.text.trim().isEmpty
            ? null
            : _fieldNumber(_dealRevenue))
        ..['reported_ebitda'] = (_dealEbitda.text.trim().isEmpty
            ? null
            : _fieldNumber(_dealEbitda))
        ..['available_capital'] = (_dealCapital.text.trim().isEmpty
            ? null
            : _fieldNumber(_dealCapital));
      final price = _fieldNumber(_dealPrice);
      await DealRoomService.updateDealProfile(
        roomId: _room.id,
        title: _dealTitle.text,
        location: _dealLocation.text,
        purchasePrice: price,
        profileSnapshot: snapshot,
      );
      _room = DealRoom(
        id: _room.id,
        userId: _room.userId,
        title: _dealTitle.text.trim(),
        address: _dealLocation.text.trim(),
        city: _dealLocation.text.trim(),
        purchasePrice: price,
        timeline: _room.timeline,
        goals: _room.goals,
        status: _room.status,
        propertySnapshot: snapshot,
        riskSnapshot: _room.riskSnapshot,
        sharingPreferences: _room.sharingPreferences,
        updatedAt: DateTime.now(),
        transactionType: _room.transactionType,
        dealKind: _room.dealKind,
        currentStage: _room.currentStage,
        targetCloseDate: _room.targetCloseDate,
        archivedAt: _room.archivedAt,
        completedTaskCount: _room.completedTaskCount,
        totalTaskCount: _room.totalTaskCount,
        currentStep: _room.currentStep,
        blockedTaskCount: _room.blockedTaskCount,
        nextDueAt: _room.nextDueAt,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: SiteText(
              contentKey: 'copy.deal_rooms_page.m60',
              literal: true,
              'Deal profile saved.',
            ),
          ),
        );
      }
      _refresh();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: SiteCopyText(
              'buyer.intake.save.error',
              'Could not save the deal profile. Your entries are still here; please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setSharing(String key, bool value) async {
    final preferences = Map<String, dynamic>.from(_room.sharingPreferences);
    preferences[key] = value;
    await DealRoomService.updateSharing(_room.id, preferences);
    if (!mounted) return;
    setState(() {
      _room = DealRoom(
        id: _room.id,
        userId: _room.userId,
        title: _room.title,
        address: _room.address,
        city: _room.city,
        purchasePrice: _room.purchasePrice,
        timeline: _room.timeline,
        goals: _room.goals,
        status: _room.status,
        propertySnapshot: _room.propertySnapshot,
        riskSnapshot: _room.riskSnapshot,
        sharingPreferences: preferences,
        updatedAt: DateTime.now(),
        transactionType: _room.transactionType,
        dealKind: _room.dealKind,
        currentStage: _room.currentStage,
        targetCloseDate: _room.targetCloseDate,
        archivedAt: _room.archivedAt,
        completedTaskCount: _room.completedTaskCount,
        totalTaskCount: _room.totalTaskCount,
        currentStep: _room.currentStep,
        blockedTaskCount: _room.blockedTaskCount,
        nextDueAt: _room.nextDueAt,
      );
    });
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      await DealRoomService.uploadDocument(_room.id, result.files.single);
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              contentKey: 'copy.deal_rooms_page.m61',
              literal: false,
              '$error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(primary: _purple, surface: _surface),
      scaffoldBackgroundColor: _paper,
      textTheme: Theme.of(
        context,
      ).textTheme.apply(bodyColor: _ink, displayColor: _ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF85817A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _line),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFFF8F6F1),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
        title: Row(
          children: [
            const HomeBrandButton(size: 48, dark: false),
            const SizedBox(width: 18),
            Container(width: 1, height: 28, color: _line),
            const SizedBox(width: 18),
            Flexible(
              child: SiteText(
                contentKey: 'copy.deal_rooms_page.m62',
                literal: false,
                _room.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 720) _privacyPill(),
          IconButton(
            onPressed: _openIntroductions,
            tooltip: 'Introductions',
            icon: const Icon(Icons.forum_outlined),
          ),
          const SizedBox(width: 8),
          AppNavigationMenu(
            side: _room.isBusiness
                ? PlatformSide.business
                : PlatformSide.property,
            dark: false,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<DealRoomBundle>(
        future: _bundle,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bundle = snapshot.data!;
          return LayoutBuilder(
            builder: (context, box) {
              final desktop = box.maxWidth >= 980;
              if (!desktop) return _mobileDashboard(bundle);
              return Row(
                children: [
                  _dashboardRail(),
                  const VerticalDivider(width: 1, thickness: 1, color: _line),
                  Expanded(
                    child: Column(
                      children: [
                        _dashboardHeader(bundle),
                        const Divider(height: 1, color: _line),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 26, 28, 64),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1040,
                                ),
                                child: _workspace(bundle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: _line),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: _introductionsOpen ? 360 : 64,
                    color: const Color(0xFFF8F6F1),
                    child: _introductionsOpen
                        ? _introductionsPanel()
                        : _collapsedIntroductions(),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );

  void _openIntroductions() {
    if (MediaQuery.sizeOf(context).width >= 980) {
      setState(() => _introductionsOpen = !_introductionsOpen);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F6F1),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: _introductionsPanel(),
        ),
      ),
    );
  }

  void _closeIntroductions() {
    if (MediaQuery.sizeOf(context).width < 980 &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _introductionsOpen = false);
  }

  Widget _privacyPill() => Container(
    margin: const EdgeInsets.symmetric(vertical: 18),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EEE9),
      borderRadius: BorderRadius.circular(30),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: _purple),
        SizedBox(width: 6),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m63',
          literal: true,
          'PRIVATE',
          style: TextStyle(
            color: _purple,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );

  Widget _dashboardRail() => Container(
    width: 78,
    color: const Color(0xFFF8F6F1),
    padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _railButton(
                _DealWorkspaceView.overview,
                Icons.space_dashboard_outlined,
                'Overview',
              ),
              _railButton(
                _DealWorkspaceView.profile,
                Icons.business_outlined,
                'Deal profile',
              ),
              _railButton(
                _DealWorkspaceView.financials,
                Icons.calculate_outlined,
                'Financial model',
              ),
              _railButton(
                _DealWorkspaceView.evaluation,
                Icons.radar_outlined,
                'Evaluation',
              ),
              _railButton(
                _DealWorkspaceView.plan,
                Icons.account_tree_outlined,
                'Plan',
              ),
              _railButton(
                _DealWorkspaceView.vault,
                Icons.folder_copy_outlined,
                'Vault',
              ),
              _railButton(
                _DealWorkspaceView.team,
                Icons.groups_2_outlined,
                'Team',
              ),
              _railButton(
                _DealWorkspaceView.timeline,
                Icons.timeline_outlined,
                'Timeline',
              ),
              _railButton(
                _DealWorkspaceView.privacy,
                Icons.visibility_off_outlined,
                'Privacy',
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              setState(() => _introductionsOpen = !_introductionsOpen),
          tooltip: _introductionsOpen
              ? 'Hide introductions'
              : 'Show introductions',
          icon: Icon(
            _introductionsOpen
                ? Icons.view_sidebar_outlined
                : Icons.forum_outlined,
            color: _purple,
          ),
        ),
      ],
    ),
  );

  Widget _railButton(_DealWorkspaceView view, IconData icon, String tooltip) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _workspaceView = view),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _workspaceView == view ? _purple : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _workspaceView == view ? _purple : _line,
                ),
              ),
              child: Icon(
                icon,
                size: 21,
                color: _workspaceView == view ? Colors.white : _ink,
              ),
            ),
          ),
        ),
      );

  Widget _dashboardHeader(DealRoomBundle bundle) => Container(
    width: double.infinity,
    color: Colors.white.withValues(alpha: .68),
    padding: const EdgeInsets.fromLTRB(30, 20, 30, 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SiteText(
                contentKey: 'copy.deal_rooms_page.m64',
                literal: false,
                _workspaceLabel.toUpperCase(),
                style: const TextStyle(
                  color: _purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              SiteText(
                contentKey: 'copy.deal_rooms_page.m65',
                literal: false,
                _workspaceTitle,
                style: const TextStyle(
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                ),
              ),
            ],
          ),
        ),
        _headerFact(
          '${bundle.tasks.where((task) => task.completed).length}/${bundle.tasks.length}',
          'TASKS',
        ),
        const SizedBox(width: 28),
        _headerFact(
          _targetDate == null
              ? 'NOT SET'
              : DateFormat.MMMd().format(_targetDate!),
          'TARGET CLOSE',
        ),
      ],
    ),
  );

  String get _workspaceLabel => switch (_workspaceView) {
    _DealWorkspaceView.overview => 'Deal command centre',
    _DealWorkspaceView.profile => 'Editable source record',
    _DealWorkspaceView.financials => 'Acquisition economics',
    _DealWorkspaceView.evaluation => 'Evidence and risk',
    _DealWorkspaceView.plan => 'Guided execution',
    _DealWorkspaceView.vault => 'Secure records',
    _DealWorkspaceView.team => 'People and decisions',
    _DealWorkspaceView.timeline => 'Stage and activity',
    _DealWorkspaceView.privacy => 'Anonymous publishing controls',
  };

  String get _workspaceTitle => switch (_workspaceView) {
    _DealWorkspaceView.overview => 'Overview',
    _DealWorkspaceView.profile => 'Deal profile',
    _DealWorkspaceView.financials => 'Financial model',
    _DealWorkspaceView.evaluation => 'Affinity evaluation',
    _DealWorkspaceView.plan => 'Transaction plan',
    _DealWorkspaceView.vault => 'Document vault',
    _DealWorkspaceView.team => 'Deal team',
    _DealWorkspaceView.timeline => 'Deal timeline',
    _DealWorkspaceView.privacy => 'Privacy preview',
  };

  Widget _headerFact(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      SiteText(
        contentKey: 'copy.deal_rooms_page.m66',
        literal: false,
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      SiteText(
        contentKey: 'copy.deal_rooms_page.m67',
        literal: false,
        label,
        style: const TextStyle(
          color: _lilac,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _workspace(DealRoomBundle bundle) => switch (_workspaceView) {
    _DealWorkspaceView.overview => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_room.isBusiness) _businessSecurityBoundary(),
        if (_room.isBusiness) const SizedBox(height: 18),
        _commandBar(bundle.tasks),
        const SizedBox(height: 18),
        _metrics(),
        const SizedBox(height: 22),
        _overviewPulse(bundle),
      ],
    ),
    _DealWorkspaceView.profile => _overview(),
    _DealWorkspaceView.financials => _financialWorkspace(),
    _DealWorkspaceView.evaluation => _evaluationWorkspace(),
    _DealWorkspaceView.plan => _checklist(bundle.tasks, bundle.members),
    _DealWorkspaceView.vault =>
      (_room.ownedByCurrentUser ||
              _room.sharingPreferences['documents'] == true)
          ? _documents(bundle.documents, bundle.documentEvents)
          : _restrictedVault(),
    _DealWorkspaceView.team => Column(
      children: [
        _team(bundle.members),
        const SizedBox(height: 18),
        _notes(bundle.notes),
      ],
    ),
    _DealWorkspaceView.timeline => _timelineWorkspace(bundle),
    _DealWorkspaceView.privacy => _privacyWorkspace(),
  };

  Widget _restrictedVault() => _card(
    'Private document vault',
    const SiteText(
      contentKey: 'copy.deal_rooms_page.14',
      literal: true,
      'The buyer has not enabled document access for this workspace.',
      style: TextStyle(color: _lilac),
    ),
  );

  Widget _overviewPulse(DealRoomBundle bundle) {
    final next = bundle.tasks.cast<DealRoomTask?>().firstWhere(
      (task) => task != null && !task.completed,
      orElse: () => null,
    );
    final blocked = bundle.tasks.where((task) => task.blocked).toList();
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth >= 720
            ? (box.maxWidth - 16) / 2
            : box.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: width,
              child: _dashboardFeature(
                Icons.bolt_outlined,
                'NEXT ACTION',
                next?.title ?? 'All guided actions are complete',
                next?.details ??
                    'Review the deal and prepare the next decision.',
                action: next == null ? null : 'OPEN PLAN',
                onTap: next == null
                    ? null
                    : () => setState(
                        () => _workspaceView = _DealWorkspaceView.plan,
                      ),
              ),
            ),
            SizedBox(
              width: width,
              child: _dashboardFeature(
                blocked.isEmpty
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                'DEAL HEALTH',
                blocked.isEmpty
                    ? 'No recorded blockers'
                    : '${blocked.length} blocker${blocked.length == 1 ? '' : 's'} need attention',
                blocked.isEmpty
                    ? 'The workspace is moving without a recorded obstruction.'
                    : blocked.first.blockerNote,
                action: blocked.isEmpty ? 'VIEW EVALUATION' : 'RESOLVE IN PLAN',
                onTap: () => setState(
                  () => _workspaceView = blocked.isEmpty
                      ? _DealWorkspaceView.evaluation
                      : _DealWorkspaceView.plan,
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: _dashboardFeature(
                Icons.lock_person_outlined,
                'MEMBER STUDIO',
                'Private until you submit',
                'Affinity reviews the deal before any anonymous opportunity is shown to members.',
                action: 'PRIVACY PREVIEW',
                onTap: () =>
                    setState(() => _workspaceView = _DealWorkspaceView.privacy),
              ),
            ),
            SizedBox(
              width: width,
              child: _dashboardFeature(
                Icons.forum_outlined,
                'INTRODUCTIONS',
                'Professional responses stay beside the deal',
                'Compare concise offers and choose when your identity can be shared.',
                action: 'OPEN INBOX',
                onTap: _openIntroductions,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dashboardFeature(
    IconData icon,
    String eyebrow,
    String title,
    String description, {
    String? action,
    VoidCallback? onTap,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 210),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _purple, size: 23),
        const SizedBox(height: 18),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m68',
          literal: false,
          eyebrow,
          style: const TextStyle(
            color: _purple,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m69',
          literal: false,
          title,
          style: const TextStyle(
            fontSize: 18,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m70',
          literal: false,
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _lilac, fontSize: 11, height: 1.45),
        ),
        const SizedBox(height: 14),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: SiteText(
              contentKey: 'copy.deal_rooms_page.m71',
              literal: false,
              action,
            ),
          ),
      ],
    ),
  );

  Widget _financialWorkspace() {
    final risk = _room.riskSnapshot;
    final cash = (risk['cash_after_owner_salary'] as num?)?.toDouble();
    final dscr = (risk['dscr'] as num?)?.toDouble();
    final viability = (risk['viability_score'] as num?)?.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _workspaceNotice(
          Icons.calculate_outlined,
          'Live acquisition inputs',
          'Edit the figures you know now. Use the full Deal Screen when you are ready for detailed debt, add-back, working-capital and scenario assumptions.',
        ),
        const SizedBox(height: 18),
        _card(
          'Core financial profile',
          Column(
            children: [
              _financialInput(_dealPrice, 'Purchase price'),
              const SizedBox(height: 12),
              _financialInput(_dealRevenue, 'Annual revenue'),
              const SizedBox(height: 12),
              _financialInput(_dealEbitda, 'Reported EBITDA'),
              const SizedBox(height: 12),
              _financialInput(_dealCapital, 'Available buyer capital'),
              if (_room.ownedByCurrentUser) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveDealProfile,
                    icon: const Icon(Icons.save_outlined, size: 17),
                    label: SiteText(
                      contentKey: 'copy.deal_rooms_page.m72',
                      literal: false,
                      _saving ? 'SAVING…' : 'SAVE FINANCIALS',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metric(
              'CASH AFTER OWNER',
              cash == null
                  ? 'PENDING'
                  : NumberFormat.compactCurrency(
                      symbol: '${_room.currency} ',
                    ).format(cash),
            ),
            _metric(
              'ACQUISITION DSCR',
              dscr == null ? 'PENDING' : '${dscr.toStringAsFixed(2)}×',
            ),
            _metric(
              'VIABILITY',
              viability == null ? 'PENDING' : '${viability.round()}/100',
            ),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BusinessAcquisitionPage(),
            ),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: const SiteText(
            contentKey: 'copy.deal_rooms_page.15',
            literal: true,
            'OPEN FULL DEAL SCREEN',
          ),
        ),
      ],
    );
  }

  Widget _financialInput(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        enabled: _room.ownedByCurrentUser,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          label: siteInputCopy(
            label,
            contentKey: 'copy.deal_rooms_page.field.dynamic3',
          ),
          prefixText: '${_room.currency} ',
          hint: SiteText(
            'Not known yet',
            contentKey: 'copy.deal_rooms_page.mfield1',
            literal: true,
          ),
        ),
      );

  Widget _evaluationWorkspace() {
    final risk = (_room.riskSnapshot['risk_score'] as num?)?.toDouble();
    final viability = (_room.riskSnapshot['viability_score'] as num?)
        ?.toDouble();
    final dscr = (_room.riskSnapshot['dscr'] as num?)?.toDouble();
    final evidence = <String, bool>{
      'Purchase price recorded': _room.purchasePrice > 0,
      'Revenue supplied':
          (_room.propertySnapshot['annual_revenue'] as num?) != null,
      'EBITDA supplied':
          (_room.propertySnapshot['reported_ebitda'] as num?) != null,
      'Capital plan supplied':
          (_room.propertySnapshot['available_capital'] as num?) != null,
      'Target close recorded': _room.targetCloseDate != null,
      'Private document uploaded later': false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _scoreDial('VIABILITY', viability, reverse: false),
            _scoreDial('RISK', risk, reverse: true),
            _scoreDial(
              'DSCR',
              dscr == null ? null : (dscr / 2.5 * 100).clamp(0, 100).toDouble(),
              reverse: false,
              valueLabel: dscr == null ? null : '${dscr.toStringAsFixed(2)}×',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _card(
          'Evidence readiness',
          Column(
            children: evidence.entries
                .map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      entry.value
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: entry.value ? _purple : _lilac,
                    ),
                    title: SiteText(
                      contentKey: 'copy.deal_rooms_page.m73',
                      literal: false,
                      entry.key,
                      style: TextStyle(
                        fontWeight: entry.value
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: SiteText(
                      contentKey: 'copy.deal_rooms_page.m74',
                      literal: false,
                      entry.value ? 'READY' : 'MISSING',
                      style: TextStyle(
                        color: entry.value ? _purple : const Color(0xFF9D3A32),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        _workspaceNotice(
          Icons.info_outline_rounded,
          'Affinity review is evidence-led',
          'Scores guide screening; they do not replace quality of earnings, legal, tax, lender, or operational diligence.',
        ),
      ],
    );
  }

  Widget _scoreDial(
    String label,
    double? value, {
    required bool reverse,
    String? valueLabel,
  }) {
    final normalized = (value ?? 0).clamp(0, 100).toDouble();
    final good = reverse ? normalized <= 35 : normalized >= 65;
    return Container(
      width: 210,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 58,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: normalized / 100,
                  strokeWidth: 7,
                  color: good ? _purple : const Color(0xFFB36A46),
                  backgroundColor: const Color(0xFFE7E2DA),
                ),
                Center(
                  child: SiteText(
                    contentKey: 'copy.deal_rooms_page.m75',
                    literal: false,
                    value == null ? '—' : '${normalized.round()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m76',
                  literal: false,
                  valueLabel ??
                      (value == null ? 'PENDING' : '${normalized.round()}/100'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m77',
                  literal: false,
                  label,
                  style: const TextStyle(
                    color: _lilac,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineWorkspace(DealRoomBundle bundle) {
    final stages = DealRoomService.stagesFor(_room.dealKind);
    final currentIndex = stages.indexOf(_room.currentStage);
    return _card(
      'Acquisition stage map',
      Column(
        children: [
          for (var index = 0; index < stages.length; index++)
            _timelineStage(
              stages[index],
              index < currentIndex,
              index == currentIndex,
              bundle.tasks
                  .where((task) => task.stage == stages[index])
                  .toList(),
              last: index == stages.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _timelineStage(
    String stage,
    bool complete,
    bool current,
    List<DealRoomTask> tasks, {
    required bool last,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 38,
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: current || complete ? _purple : const Color(0xFFE6E2DA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                complete
                    ? Icons.check
                    : current
                    ? Icons.arrow_forward
                    : Icons.circle,
                size: current || complete ? 15 : 7,
                color: current || complete ? Colors.white : _lilac,
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 54,
                color: complete ? _purple : _line,
              ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SiteText(
                contentKey: 'copy.deal_rooms_page.m78',
                literal: false,
                stage.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  color: current ? _purple : _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 4),
              SiteText(
                templateValues: {
                  'value1': '${tasks.where((task) => task.completed).length}',
                  'value2': '${tasks.length}',
                },
                contentKey: 'copy.deal_rooms_page.m79',
                literal: false,
                "{{value1}}/{{value2}} actions complete",
                style: const TextStyle(color: _lilac, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _privacyWorkspace() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _workspaceNotice(
        Icons.visibility_off_outlined,
        'You control the boundary',
        'Members never see the buyer name, exact address, raw assessment, documents, or contact information in the anonymous feed.',
      ),
      const SizedBox(height: 18),
      _card(
        'Professional workspace access',
        Column(
          children: [
            _privacyToggle(
              'financials',
              'Share financial model',
              'Approved deal-team professionals can view the financial summary.',
            ),
            _privacyToggle(
              'risk',
              'Share Affinity evaluation',
              'Approved deal-team professionals can view risk and viability outputs.',
            ),
            _privacyToggle(
              'documents',
              'Allow document access',
              'Only explicitly approved participants can open the private vault.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _card(
        'What Member Studio sees',
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F1EB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: _purple,
                    child: Icon(
                      Icons.lock_person_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 10),
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m80',
                    literal: true,
                    'ANONYMOUS BUYER · AFFINITY REVIEWED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SiteText(
                contentKey: 'copy.deal_rooms_page.m81',
                literal: false,
                _room.propertySnapshot['industry'] as String? ??
                    'Business acquisition opportunity',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              SiteText(
                contentKey: 'copy.deal_rooms_page.m82',
                literal: false,
                _room.city.isEmpty ? 'Region private' : _room.city,
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const SiteText(
                contentKey: 'copy.deal_rooms_page.16',
                literal: true,
                'Affinity writes and approves the summary, price band, support needs, and score label before publication.',
                style: TextStyle(color: _lilac, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _privacyToggle(String key, String title, String subtitle) =>
      SwitchListTile(
        value: _room.sharingPreferences[key] == true,
        contentPadding: EdgeInsets.zero,
        title: SiteText(
          contentKey: 'copy.deal_rooms_page.m83',
          literal: false,
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: SiteText(
          contentKey: 'copy.deal_rooms_page.m84',
          literal: false,
          subtitle,
          style: const TextStyle(color: _lilac, fontSize: 11),
        ),
        onChanged: _room.ownedByCurrentUser
            ? (value) => _setSharing(key, value)
            : null,
      );

  Widget _workspaceNotice(IconData icon, String title, String text) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EEE9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC7D7CF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m85',
                    literal: false,
                    title,
                    style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m86',
                    literal: false,
                    text,
                    style: const TextStyle(
                      color: Color(0xFF405D52),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _collapsedIntroductions() => Column(
    children: [
      const SizedBox(height: 16),
      IconButton(
        onPressed: () => setState(() => _introductionsOpen = true),
        tooltip: 'Open introductions',
        icon: const Icon(Icons.forum_outlined, color: _purple),
      ),
      const SizedBox(height: 8),
      const RotatedBox(
        quarterTurns: 1,
        child: SiteText(
          contentKey: 'copy.deal_rooms_page.m87',
          literal: true,
          'INTRODUCTIONS',
          style: TextStyle(
            color: _purple,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    ],
  );

  Widget _introductionsPanel() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 17, 10, 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE5EEE9),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.forum_outlined, color: _purple, size: 18),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m88',
                    literal: true,
                    'Introductions',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m89',
                    literal: true,
                    'Private professional pitches',
                    style: TextStyle(color: _lilac, fontSize: 10),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _closeIntroductions,
              tooltip: 'Collapse',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: _line),
      Expanded(
        child: FutureBuilder<List<MemberDealPitch>>(
          future: _introductions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final pitches = snapshot.data ?? const <MemberDealPitch>[];
            if (!_room.ownedByCurrentUser) {
              return _memberConversationBoundary();
            }
            if (pitches.isEmpty) return _emptyIntroductions();
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: pitches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _introductionTile(pitches[index]),
            );
          },
        ),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFFE5EEE9),
          border: Border(top: BorderSide(color: _line)),
        ),
        child: const SiteText(
          contentKey: 'copy.deal_rooms_page.17',
          literal: true,
          'Your identity stays private until you accept an introduction.',
          style: TextStyle(
            color: _purple,
            fontSize: 10,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget _emptyIntroductions() => const Padding(
    padding: EdgeInsets.all(26),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mark_unread_chat_alt_outlined, size: 34, color: _lilac),
        SizedBox(height: 14),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m90',
          literal: true,
          'No introductions yet',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m91',
          literal: true,
          'When a verified Affinity member responds to an approved anonymous opportunity, their short pitch will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _lilac, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );

  Widget _memberConversationBoundary() => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_person_outlined, size: 34, color: _purple),
        SizedBox(height: 14),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m92',
          literal: true,
          'Buyer identity protected',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m93',
          literal: true,
          'Use the Member Studio opportunity feed to send a concise introduction. Direct contact opens only if the buyer accepts.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _lilac, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );

  Widget _introductionTile(MemberDealPitch pitch) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE5EEE9),
              child: SiteText(
                contentKey: 'copy.deal_rooms_page.m94',
                literal: false,
                pitch.companyName.isNotEmpty
                    ? pitch.companyName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m95',
                    literal: false,
                    pitch.companyName.isEmpty
                        ? pitch.providerName
                        : pitch.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m96',
                    literal: false,
                    pitch.providerType,
                    style: const TextStyle(color: _lilac, fontSize: 9),
                  ),
                ],
              ),
            ),
            _pitchStatus(pitch.status),
          ],
        ),
        const SizedBox(height: 11),
        if (pitch.offerSummary.isNotEmpty) ...[
          SiteText(
            contentKey: 'copy.deal_rooms_page.m97',
            literal: false,
            pitch.offerSummary,
            style: const TextStyle(
              color: _purple,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
        ],
        SiteText(
          contentKey: 'copy.deal_rooms_page.m98',
          literal: false,
          pitch.pitch,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, height: 1.45),
        ),
        if (pitch.status == 'submitted' || pitch.status == 'shortlisted') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToIntroduction(pitch, 'declined'),
                  child: const SiteText(
                    contentKey: 'copy.deal_rooms_page.18',
                    literal: true,
                    'PASS',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _respondToIntroduction(pitch, 'accepted'),
                  child: const SiteText(
                    contentKey: 'copy.deal_rooms_page.19',
                    literal: true,
                    'CONNECT',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _pitchStatus(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EEE9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: SiteText(
      contentKey: 'copy.deal_rooms_page.m99',
      literal: false,
      status.toUpperCase(),
      style: const TextStyle(
        color: _purple,
        fontSize: 7,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Future<void> _respondToIntroduction(
    MemberDealPitch pitch,
    String status,
  ) async {
    try {
      await MemberDealMarketplaceService.respondToPitch(pitch.id, status);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              contentKey: 'copy.deal_rooms_page.m100',
              literal: false,
              status == 'accepted'
                  ? 'Introduction accepted. Your contact details are now shared.'
                  : 'Introduction passed.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              contentKey: 'copy.deal_rooms_page.m101',
              literal: false,
              '$error',
            ),
          ),
        );
    }
  }

  Widget _mobileDashboard(DealRoomBundle bundle) => Column(
    children: [
      _dashboardHeader(bundle),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
          child: _workspace(bundle),
        ),
      ),
      Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F6F1),
          border: Border(top: BorderSide(color: _line)),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          children: [
            _mobileNav(
              _DealWorkspaceView.overview,
              Icons.space_dashboard_outlined,
              'Overview',
            ),
            _mobileNav(
              _DealWorkspaceView.profile,
              Icons.business_outlined,
              'Profile',
            ),
            _mobileNav(
              _DealWorkspaceView.financials,
              Icons.calculate_outlined,
              'Financials',
            ),
            _mobileNav(
              _DealWorkspaceView.evaluation,
              Icons.radar_outlined,
              'Evaluation',
            ),
            _mobileNav(
              _DealWorkspaceView.plan,
              Icons.account_tree_outlined,
              'Plan',
            ),
            _mobileNav(
              _DealWorkspaceView.vault,
              Icons.folder_copy_outlined,
              'Vault',
            ),
            _mobileNav(
              _DealWorkspaceView.team,
              Icons.groups_2_outlined,
              'Team',
            ),
            _mobileNav(
              _DealWorkspaceView.timeline,
              Icons.timeline_outlined,
              'Timeline',
            ),
            _mobileNav(
              _DealWorkspaceView.privacy,
              Icons.visibility_off_outlined,
              'Privacy',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _mobileNav(_DealWorkspaceView view, IconData icon, String label) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _workspaceView = view),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: _workspaceView == view
                  ? const Color(0xFFE5EEE9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: _workspaceView == view ? _purple : _lilac,
                ),
                const SizedBox(width: 7),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m102',
                  literal: false,
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: _workspaceView == view
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _roomHeader(DealRoomBundle bundle) => TopoBackground(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 52),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HomeBrandButton(size: 44),
                    const Spacer(),
                    AppNavigationMenu(
                      side: _room.isBusiness
                          ? PlatformSide.business
                          : PlatformSide.property,
                    ),
                  ],
                ),
                const SizedBox(height: 52),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m103',
                  literal: false,
                  _room.ownedByCurrentUser
                      ? (_room.isBusiness
                            ? 'PRIVATE ACQUISITION WORKSPACE'
                            : 'PRIVATE PROPERTY WORKSPACE')
                      : 'SHARED PROFESSIONAL WORKSPACE',
                  style: const TextStyle(
                    color: _lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m104',
                  literal: false,
                  _room.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 14),
                SiteText(
                  templateValues: {
                    'value1': '${_room.dealKind.toUpperCase()}',
                    'value2':
                        '${_room.currentStage.toUpperCase().replaceAll('_', ' ')}',
                    'value3': '${bundle.members.length}',
                    'value4': '${bundle.members.length == 1 ? '' : 'S'}',
                  },
                  contentKey: 'copy.deal_rooms_page.m105',
                  literal: false,
                  "{{value1}} · {{value2}} · {{value3}} TEAM MEMBER{{value4}}",
                  style: const TextStyle(
                    color: Color(0xFF9B9B98),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _commandBar(List<DealRoomTask> tasks) {
    final next = tasks.cast<DealRoomTask?>().firstWhere(
      (task) =>
          task != null && !task.completed && task.stage == _room.currentStage,
      orElse: () => tasks.cast<DealRoomTask?>().firstWhere(
        (task) => task != null && !task.completed,
        orElse: () => null,
      ),
    );
    final blockers = tasks.where((task) => task.blocked).length;
    return TopoCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(19),
      child: Wrap(
        spacing: 26,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SiteText(
                  contentKey: 'copy.deal_rooms_page.20',
                  literal: true,
                  'NEXT ACTION',
                  style: TextStyle(
                    color: _lilac,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SiteText(
                  contentKey: 'copy.deal_rooms_page.m106',
                  literal: false,
                  next?.title ?? 'All guided tasks are complete',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _commandMetric(
            blockers == 0 ? 'CLEAR' : '$blockers',
            blockers == 0 ? 'NO BLOCKERS' : 'BLOCKERS',
            blockers > 0,
          ),
          _commandMetric(
            _targetDate == null
                ? 'NOT SET'
                : DateFormat.MMMd().format(_targetDate!),
            'TARGET CLOSE',
            false,
          ),
        ],
      ),
    );
  }

  Widget _commandMetric(String value, String label, bool alert) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SiteText(
        contentKey: 'copy.deal_rooms_page.m107',
        literal: false,
        value,
        style: TextStyle(
          color: alert ? const Color(0xFFFF8177) : Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      SiteText(
        contentKey: 'copy.deal_rooms_page.m108',
        literal: false,
        label,
        style: const TextStyle(color: Color(0xFF9D9DAC), fontSize: 8),
      ),
    ],
  );

  Widget _metrics() {
    final financialsVisible =
        _room.ownedByCurrentUser ||
        _room.sharingPreferences['financials'] != false;
    final riskVisible =
        _room.ownedByCurrentUser || _room.sharingPreferences['risk'] != false;
    final risk =
        (_room.riskSnapshot[_room.isBusiness ? 'risk_score' : 'risk'] as num?)
            ?.toDouble();
    final viability = (_room.riskSnapshot['viability_score'] as num?)
        ?.toDouble();
    final capRate = (_room.riskSnapshot['capRate'] as num?)?.toDouble();
    final dscr = (_room.riskSnapshot['dscr'] as num?)?.toDouble();
    final monthly = (_room.riskSnapshot['monthlyCarry'] as num?)?.toDouble();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metric(
          'PURCHASE PRICE',
          !financialsVisible
              ? 'PRIVATE'
              : _room.purchasePrice <= 0
              ? '—'
              : NumberFormat.compactCurrency(
                  symbol: '${_room.currency} ',
                ).format(_room.purchasePrice),
        ),
        _metric(
          _room.isBusiness ? 'ACQUISITION RISK' : 'RISK',
          !riskVisible
              ? 'PRIVATE'
              : (risk == null ? '—' : '${risk.round()}/100'),
        ),
        if (_room.isBusiness)
          _metric(
            'VIABILITY',
            !riskVisible
                ? 'PRIVATE'
                : (viability == null ? '—' : '${viability.round()}/100'),
          )
        else
          _metric(
            'CAP RATE',
            !financialsVisible
                ? 'PRIVATE'
                : (capRate == null ? '—' : '${capRate.toStringAsFixed(2)}%'),
          ),
        _metric(
          _room.isBusiness ? 'ACQUISITION DSCR' : 'DSCR',
          !financialsVisible
              ? 'PRIVATE'
              : (dscr == null ? '—' : '${dscr.toStringAsFixed(2)}×'),
        ),
        _metric(
          _room.isBusiness ? 'CASH AFTER OWNER' : 'MONTHLY CARRY',
          !financialsVisible
              ? 'PRIVATE'
              : _room.isBusiness
              ? NumberFormat.simpleCurrency(
                  name: _room.currency,
                  decimalDigits: 0,
                ).format(
                  (_room.riskSnapshot['cash_after_owner_salary'] as num?)
                          ?.toDouble() ??
                      0,
                )
              : monthly == null
              ? '—'
              : NumberFormat.simpleCurrency(
                  name: _room.currency,
                  decimalDigits: 0,
                ).format(monthly),
        ),
      ],
    );
  }

  Widget _businessSecurityBoundary() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF2C879)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, color: Color(0xFF8A5800)),
        SizedBox(width: 11),
        Expanded(
          child: SiteText(
            contentKey: 'copy.deal_rooms_page.m109',
            literal: true,
            'PRIVATE DEAL VAULT · Access is restricted to this Deal Room, files are validated against an allowlist, downloads require a live signed-in session, and file activity is audited. Do not upload executable files, passwords, government IDs or banking credentials. Independent security testing and malware scanning remain required before storing the most sensitive M&A records.',
            style: TextStyle(
              color: Color(0xFF6D4805),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _metric(String label, String value) => Container(
    width: 190,
    constraints: const BoxConstraints(minHeight: 104),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SiteText(
          contentKey: 'copy.deal_rooms_page.m110',
          literal: false,
          value,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        SiteText(
          contentKey: 'copy.deal_rooms_page.m111',
          literal: false,
          label,
          style: const TextStyle(color: Color(0xFF777785), fontSize: 9),
        ),
      ],
    ),
  );

  Widget _overview() => _card(
    'Deal brief',
    Column(
      children: [
        if (_room.ownedByCurrentUser) DealIntakeForm(controllers: _extra),
        TextField(
          controller: _dealDetails,
          enabled: _room.ownedByCurrentUser,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          decoration: const InputDecoration(
            label: SiteText(
              'Deal details',
              contentKey: 'copy.deal_rooms_page.field13',
              literal: true,
            ),
            hint: SiteText(
              'Describe the business, what attracts you to it, and what you are trying to accomplish.',
              contentKey: 'copy.deal_rooms_page.field14',
              literal: true,
            ),
            helperText:
                'Required before this deal can be submitted for review.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _goals,
          enabled: _room.ownedByCurrentUser,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            label: SiteText(
              'Goals and decision context',
              contentKey: 'copy.deal_rooms_page.field15',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _timeline,
          enabled: _room.ownedByCurrentUser,
          decoration: const InputDecoration(
            label: SiteText(
              'Timeline or target closing date',
              contentKey: 'copy.deal_rooms_page.field16',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_room.ownedByCurrentUser)
          DropdownButtonFormField<String>(
            initialValue: _room.currentStage,
            decoration: const InputDecoration(
              label: SiteText(
                'Current step',
                contentKey: 'copy.deal_rooms_page.field17',
                literal: true,
              ),
            ),
            items: DealRoomService.stagesFor(_room.dealKind)
                .map(
                  (stage) => DropdownMenuItem(
                    value: stage,
                    child: SiteText(
                      contentKey: 'copy.deal_rooms_page.m112',
                      literal: false,
                      stage.toUpperCase().replaceAll('_', ' '),
                    ),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => value == null
                      ? null
                      : _saveRoom(_room.status, currentStage: value),
          ),
        if (_room.ownedByCurrentUser) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate:
                      _targetDate ??
                      DateTime.now().add(const Duration(days: 45)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (selected == null || !mounted) return;
                setState(() => _targetDate = selected);
                await _saveRoom(_room.status);
              },
              icon: const Icon(Icons.event_outlined),
              label: SiteText(
                contentKey: 'copy.deal_rooms_page.m113',
                literal: false,
                _targetDate == null
                    ? 'ADD TARGET CLOSING DATE'
                    : 'TARGET CLOSE · ${DateFormat.yMMMd().format(_targetDate!)}',
              ),
            ),
          ),
        ],
        if (_room.ownedByCurrentUser) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _room.status,
                  decoration: const InputDecoration(
                    label: SiteText(
                      'Deal stage',
                      contentKey: 'copy.deal_rooms_page.field18',
                      literal: true,
                    ),
                  ),
                  items:
                      const [
                            'draft',
                            'active',
                            'under_offer',
                            'closing',
                            'completed',
                            'cancelled',
                            'archived',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: SiteText(
                                contentKey: 'copy.deal_rooms_page.m114',
                                literal: false,
                                value.toUpperCase().replaceAll('_', ' '),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => value == null ? null : _saveRoom(value),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (_dealDetails.text.trim().length < 40) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: SiteText(
                                contentKey: 'copy.deal_rooms_page.m115',
                                literal: true,
                                'Add at least 40 characters of deal details before saving.',
                              ),
                            ),
                          );
                          return;
                        }
                        await _saveRoom(_room.status);
                        await _saveDealProfile();
                      },
                child: const SiteText(
                  contentKey: 'copy.deal_rooms_page.21',
                  literal: true,
                  'SAVE',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: SiteText(
              contentKey: 'copy.deal_rooms_page.m116',
              literal: true,
              'TEAM ACCESS',
              style: TextStyle(
                color: _purple,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          SwitchListTile(
            value: _room.sharingPreferences['financials'] != false,
            onChanged: (value) => _setSharing('financials', value),
            title: const SiteText(
              contentKey: 'copy.deal_rooms_page.22',
              literal: true,
              'Share financial model',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _room.sharingPreferences['risk'] != false,
            onChanged: (value) => _setSharing('risk', value),
            title: const SiteText(
              contentKey: 'copy.deal_rooms_page.23',
              literal: true,
              'Share risk assessment',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (!_room.isBusiness)
            SwitchListTile(
              value: _room.sharingPreferences['documents'] == true,
              onChanged: (value) => _setSharing('documents', value),
              title: const SiteText(
                contentKey: 'copy.deal_rooms_page.24',
                literal: true,
                'Allow document access',
              ),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ],
    ),
  );

  Widget _team(List<DealRoomMember> members) => _card(
    _room.isBusiness ? 'Acquisition team' : 'Property team',
    members.isEmpty
        ? const SiteText(
            contentKey: 'copy.deal_rooms_page.25',
            literal: true,
            'No professionals were attached when this room was created.',
          )
        : Column(
            children: members.map((member) {
              final provider = member.provider;
              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    ProfilePhoto(
                      size: 44,
                      photoUrl: provider.photoUrl,
                      exampleIndex: provider.photoIndex,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SiteText(
                            contentKey: 'copy.deal_rooms_page.m117',
                            literal: false,
                            provider.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SiteText(
                            contentKey: 'copy.deal_rooms_page.m118',
                            literal: false,
                            '${provider.jobTitle} · ${member.status}',
                            style: const TextStyle(
                              color: Color(0xFF777785),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_room.ownedByCurrentUser && member.status == 'invited')
                      PopupMenuButton<bool>(
                        onSelected: (accept) async {
                          await DealRoomService.respondToInvite(
                            member.id,
                            accept,
                          );
                          _refresh();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: true,
                            child: SiteText(
                              contentKey: 'copy.deal_rooms_page.m119',
                              literal: true,
                              'Accept workspace',
                            ),
                          ),
                          PopupMenuItem(
                            value: false,
                            child: SiteText(
                              contentKey: 'copy.deal_rooms_page.m120',
                              literal: true,
                              'Decline',
                            ),
                          ),
                        ],
                      ),
                    if (_room.ownedByCurrentUser)
                      PopupMenuButton<String>(
                        tooltip: 'Change access',
                        onSelected: (level) async {
                          await DealRoomService.updateMemberAccess(
                            member.id,
                            level,
                          );
                          _refresh();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'summary',
                            child: SiteText(
                              contentKey: 'copy.deal_rooms_page.m121',
                              literal: true,
                              'Summary access',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'standard',
                            child: SiteText(
                              contentKey: 'copy.deal_rooms_page.m122',
                              literal: true,
                              'Standard access',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'full',
                            child: SiteText(
                              contentKey: 'copy.deal_rooms_page.m123',
                              literal: true,
                              'Full access',
                            ),
                          ),
                        ],
                        child: SiteText(
                          contentKey: 'copy.deal_rooms_page.m124',
                          literal: false,
                          member.accessLevel.toUpperCase(),
                          style: const TextStyle(
                            color: _purple,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
  );

  Future<void> _editTask(
    DealRoomTask task,
    List<DealRoomMember> members,
  ) async {
    final result = await showDialog<_TaskUpdate>(
      context: context,
      builder: (_) => _TaskDialog(task: task, members: members),
    );
    if (result == null) return;
    await DealRoomService.updateTask(
      taskId: task.id,
      status: result.status,
      blockerNote: result.blockerNote,
      dueAt: result.dueAt,
      assignedProviderId: result.assignedProviderId,
    );
    _refresh();
  }

  Widget _checklist(List<DealRoomTask> tasks, List<DealRoomMember> members) {
    final complete = tasks.where((task) => task.completed).length;
    final blocked = tasks.where((task) => task.blocked).length;
    final grouped = <String, List<DealRoomTask>>{};
    for (final stage in DealRoomService.stagesFor(_room.dealKind)) {
      grouped[stage] = tasks.where((task) => task.stage == stage).toList();
    }
    for (final task in tasks) {
      if (!grouped.containsKey(task.stage)) {
        grouped.putIfAbsent(task.stage, () => []).add(task);
      }
    }
    return _card(
      'Guided transaction plan',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: tasks.isEmpty ? 0 : complete / tasks.length,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE8E8EF),
                    color: _purple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SiteText(
                templateValues: {
                  'value1': '${complete}',
                  'value2': '${tasks.length}',
                },
                contentKey: 'copy.deal_rooms_page.m125',
                literal: false,
                "{{value1}}/{{value2}} COMPLETE",
                style: const TextStyle(
                  color: _purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (blocked > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SiteText(
                templateValues: {
                  'value1': '${blocked}',
                  'value2': '${blocked == 1 ? '' : 'S'}',
                },
                contentKey: 'copy.deal_rooms_page.m126',
                literal: false,
                "{{value1}} BLOCKED TASK{{value2}} · Resolve these before the transaction can move cleanly.",
                style: const TextStyle(
                  color: Color(0xFF9D2018),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...grouped.entries
              .where((entry) => entry.value.isNotEmpty)
              .map((entry) => _stageSection(entry.key, entry.value, members)),
        ],
      ),
    );
  }

  Widget _stageSection(
    String stage,
    List<DealRoomTask> tasks,
    List<DealRoomMember> members,
  ) {
    final complete = tasks.where((task) => task.completed).length;
    final current = stage == _room.currentStage;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: current || tasks.any((task) => task.blocked),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading: Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: current ? _purple : _purple.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            complete == tasks.length ? Icons.check : Icons.arrow_forward,
            size: 16,
            color: current ? Colors.white : _purple,
          ),
        ),
        title: SiteText(
          contentKey: 'copy.deal_rooms_page.m127',
          literal: false,
          stage.toUpperCase().replaceAll('_', ' '),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: current ? _purple : _ink,
            letterSpacing: .8,
          ),
        ),
        subtitle: SiteText(
          templateValues: {
            'value1': '${complete}',
            'value2': '${tasks.length}',
          },
          contentKey: 'copy.deal_rooms_page.m128',
          literal: false,
          "{{value1}}/{{value2}} complete",
        ),
        children: tasks.map((task) => _taskRow(task, members)).toList(),
      ),
    );
  }

  Widget _taskRow(DealRoomTask task, List<DealRoomMember> members) {
    final overdue =
        task.dueAt != null &&
        !task.completed &&
        task.dueAt!.isBefore(DateTime.now());
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: task.blocked ? const Color(0xFFFFF0ED) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: task.blocked
              ? const Color(0xFFE9A39D)
              : const Color(0xFFE7E7ED),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.completed,
            onChanged: (value) async {
              await DealRoomService.toggleTask(task, value ?? false);
              _refresh();
            },
            activeColor: _purple,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m129',
                    literal: false,
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SiteText(
                      contentKey: 'copy.deal_rooms_page.m130',
                      literal: false,
                      task.details,
                      style: const TextStyle(
                        color: Color(0xFF666674),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      _taskTag(task.status, task.blocked),
                      if (task.dueAt != null)
                        _taskTag(
                          '${overdue ? 'OVERDUE' : 'DUE'} ${DateFormat.MMMd().format(task.dueAt!)}',
                          overdue,
                        ),
                      if (task.assignedProviderId != null)
                        _taskTag('ASSIGNED', false),
                    ],
                  ),
                  if (task.blockerNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SiteText(
                      templateValues: {'value1': '${task.blockerNote}'},
                      contentKey: 'copy.deal_rooms_page.m131',
                      literal: false,
                      "BLOCKER · {{value1}}",
                      style: const TextStyle(
                        color: Color(0xFF9D2018),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _editTask(task, members),
            tooltip: 'Task details',
            icon: const Icon(Icons.tune, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _taskTag(String label, bool alert) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: alert ? const Color(0xFFFFE2DC) : _purple.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: SiteText(
      contentKey: 'copy.deal_rooms_page.m132',
      literal: false,
      label.toUpperCase().replaceAll('_', ' '),
      style: TextStyle(
        color: alert ? const Color(0xFF9D2018) : _purple,
        fontSize: 7,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _notes(List<DealRoomNote> notes) => _card(
    'Shared notes',
    Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _note,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  label: SiteText(
                    'Add a decision, question or update',
                    contentKey: 'copy.deal_rooms_page.field19',
                    literal: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: () async {
                if (_note.text.trim().isEmpty) return;
                await DealRoomService.addNote(_room.id, _note.text);
                _note.clear();
                _refresh();
              },
              icon: const Icon(Icons.send),
              tooltip: 'Share note',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (notes.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: SiteText(
              contentKey: 'copy.deal_rooms_page.m133',
              literal: true,
              'No shared notes yet.',
            ),
          )
        else
          ...notes.map(
            (note) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: note.mine
                    ? _purple.withValues(alpha: .14)
                    : const Color(0xFFF0EDF7),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m134',
                    literal: false,
                    note.text,
                    style: const TextStyle(height: 1.45),
                  ),
                  const SizedBox(height: 6),
                  SiteText(
                    contentKey: 'copy.deal_rooms_page.m135',
                    literal: false,
                    '${note.mine ? 'YOU' : 'TEAM MEMBER'} · ${DateFormat.MMMd().add_jm().format(note.createdAt)}',
                    style: const TextStyle(
                      color: Color(0xFF777785),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _documents(
    List<DealRoomDocument> documents,
    List<DealRoomDocumentEvent> events,
  ) => _card(
    'Private document vault',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _uploading ? null : _uploadDocument,
          icon: _uploading
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined),
          label: SiteText(
            contentKey: 'copy.deal_rooms_page.m136',
            literal: false,
            _uploading ? 'UPLOADING…' : 'UPLOAD DOCUMENT',
          ),
        ),
        const SizedBox(height: 14),
        const SiteText(
          contentKey: 'copy.deal_rooms_page.26',
          literal: true,
          'PDF, JPG or PNG · 15 MB maximum · authenticated participants only',
          style: TextStyle(color: Color(0xFF666674), fontSize: 11),
        ),
        const SizedBox(height: 14),
        if (documents.isEmpty)
          const SiteText(
            contentKey: 'copy.deal_rooms_page.27',
            literal: true,
            'No private documents have been added.',
            style: TextStyle(color: Color(0xFF666674), fontSize: 12),
          )
        else
          ...documents.map(
            (document) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, color: _purple),
              title: SiteText(
                contentKey: 'copy.deal_rooms_page.m137',
                literal: false,
                document.fileName,
              ),
              subtitle: SiteText(
                templateValues: {
                  'value1': '${(document.fileSize / 1024).ceil()}',
                  'value2': '${document.securityStatus.toUpperCase()}',
                  'value3': '${DateFormat.MMMd().format(document.createdAt)}',
                },
                contentKey: 'copy.deal_rooms_page.m138',
                literal: false,
                "{{value1}} KB · {{value2}} · {{value3}}",
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Document actions',
                onSelected: (action) async {
                  try {
                    if (action == 'download') {
                      await DealRoomService.downloadDocument(document);
                    } else if (action == 'delete') {
                      await DealRoomService.deleteDocument(document);
                      _refresh();
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: SiteText(
                            contentKey: 'copy.deal_rooms_page.m139',
                            literal: false,
                            '$error',
                          ),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: SiteText(
                      contentKey: 'copy.deal_rooms_page.m140',
                      literal: true,
                      'Download securely',
                    ),
                  ),
                  if (_room.ownedByCurrentUser ||
                      document.uploadedBy == BackendService.user?.id)
                    const PopupMenuItem(
                      value: 'delete',
                      child: SiteText(
                        contentKey: 'copy.deal_rooms_page.m141',
                        literal: true,
                        'Delete document',
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (events.isNotEmpty) ...[
          const Divider(height: 32),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const SiteText(
              contentKey: 'copy.deal_rooms_page.28',
              literal: true,
              'File activity',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const SiteText(
              contentKey: 'copy.deal_rooms_page.29',
              literal: true,
              'Recent downloads, uploads and deletions',
            ),
            children: events
                .take(12)
                .map(
                  (event) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      event.eventType == 'downloaded'
                          ? Icons.download_done_outlined
                          : Icons.history,
                      size: 18,
                    ),
                    title: SiteText(
                      contentKey: 'copy.deal_rooms_page.m142',
                      literal: false,
                      '${event.eventType.toUpperCase()} · ${event.fileName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: SiteText(
                      contentKey: 'copy.deal_rooms_page.m143',
                      literal: false,
                      '${event.mine ? 'You' : 'Deal participant'} · ${DateFormat.MMMd().add_jm().format(event.createdAt)}',
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );

  Widget _card(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(
          contentKey: 'copy.deal_rooms_page.m144',
          literal: false,
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
