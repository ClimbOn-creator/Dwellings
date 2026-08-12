import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/platform_side.dart';
import '../services/deal_room_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/platform_switcher.dart';
import '../widgets/profile_photo.dart';
import 'business_acquisition_page.dart';
import 'platform_hub_page.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);
const _lilac = Color(0xFFBCAEFF);

class DealRoomsPage extends StatefulWidget {
  const DealRoomsPage({super.key, this.initialSide = PlatformSide.property});

  final PlatformSide initialSide;

  @override
  State<DealRoomsPage> createState() => _DealRoomsPageState();
}

class _DealRoomsPageState extends State<DealRoomsPage> {
  late Future<List<DealRoom>> _rooms;
  late PlatformSide _side;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    _rooms = DealRoomService.loadRooms();
  }

  void _refresh() => setState(() => _rooms = DealRoomService.loadRooms());

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 52),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: FutureBuilder<List<DealRoom>>(
                  future: _rooms,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 260,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final rooms = snapshot.data!
                        .where(
                          (room) => _side == PlatformSide.business
                              ? room.isBusiness
                              : !room.isBusiness,
                        )
                        .toList();
                    if (rooms.isEmpty) return _empty();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rooms.length} ACTIVE WORKSPACE${rooms.length == 1 ? '' : 'S'}',
                          style: const TextStyle(
                            color: _purple,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...rooms.map(_roomCard),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _header() => Container(
    color: _ink,
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
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const DwellingIqLogo(size: 46),
                  ),
                  const Spacer(),
                  PlatformSwitcher(
                    selected: _side,
                    onChanged: (side) => setState(() => _side = side),
                    compact: true,
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_back, size: 17),
                    label: const Text('PROFILE'),
                  ),
                ],
              ),
              const SizedBox(height: 68),
              Text(
                _side == PlatformSide.business
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
              Text(
                _side == PlatformSide.business
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
              const SizedBox(
                width: 650,
                child: Text(
                  'Turn a saved property or business assessment into a private workspace for decisions, diligence, financing, legal work and closing.',
                  style: TextStyle(
                    color: Color(0xFFC5C5D0),
                    height: 1.55,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _creating ? null : _create,
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
                label: Text(
                  _creating
                      ? 'CREATING…'
                      : _side == PlatformSide.business
                      ? 'START BUSINESS ASSESSMENT'
                      : 'CREATE FROM LATEST ANALYSIS',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _empty() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(Icons.meeting_room_outlined, size: 44, color: _purple),
        const SizedBox(height: 15),
        Text(
          _side == PlatformSide.business
              ? 'No business acquisition workspaces yet'
              : 'No property Deal Rooms yet',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _side == PlatformSide.business
              ? 'Run a DealIQ viability assessment, then create its guided acquisition workspace.'
              : 'Run and save a property analysis, then create its collaborative workspace here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF666674)),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _creating ? null : _create,
          child: Text(
            _side == PlatformSide.business
                ? 'OPEN BUSINESS ASSESSMENT'
                : 'CREATE DEAL ROOM',
          ),
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
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(17),
            ),
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
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _status(room.status),
                    if (!room.ownedByCurrentUser) _status('shared'),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  [
                    if (room.city.isNotEmpty) room.city,
                    if (room.purchasePrice > 0)
                      NumberFormat.simpleCurrency(
                        name: 'CAD',
                        decimalDigits: 0,
                      ).format(room.purchasePrice),
                    'Updated ${DateFormat.MMMd().format(room.updatedAt)}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: Color(0xFF666674),
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
                          backgroundColor: const Color(0xFFE8E8EF),
                          valueColor: const AlwaysStoppedAnimation(_purple),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
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
                Text(
                  'CURRENT STEP · ${room.currentStep.toUpperCase()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .45,
                  ),
                ),
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
    child: Text(
      value.toUpperCase().replaceAll('_', ' '),
      style: const TextStyle(
        color: _purple,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class DealRoomPage extends StatefulWidget {
  const DealRoomPage({super.key, required this.room});
  final DealRoom room;

  @override
  State<DealRoomPage> createState() => _DealRoomPageState();
}

class _DealRoomPageState extends State<DealRoomPage> {
  late DealRoom _room;
  late Future<DealRoomBundle> _bundle;
  final _note = TextEditingController();
  final _timeline = TextEditingController();
  final _goals = TextEditingController();
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _timeline.text = _room.timeline;
    _goals.text = _room.goals;
    _bundle = DealRoomService.loadBundle(_room);
  }

  @override
  void dispose() {
    _note.dispose();
    _timeline.dispose();
    _goals.dispose();
    super.dispose();
  }

  void _refresh() =>
      setState(() => _bundle = DealRoomService.loadBundle(_room));

  Future<void> _saveRoom(String status) async {
    setState(() => _saving = true);
    try {
      await DealRoomService.updateRoom(
        roomId: _room.id,
        status: status,
        timeline: _timeline.text,
        goals: _goals.text,
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
        completedTaskCount: _room.completedTaskCount,
        totalTaskCount: _room.totalTaskCount,
        currentStep: _room.currentStep,
      );
      _refresh();
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
        completedTaskCount: _room.completedTaskCount,
        totalTaskCount: _room.totalTaskCount,
        currentStep: _room.currentStep,
      );
    });
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      await DealRoomService.uploadDocument(_room.id, result.files.single);
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: FutureBuilder<DealRoomBundle>(
      future: _bundle,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bundle = snapshot.data!;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _roomHeader(bundle)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 42,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_room.isBusiness) _businessSecurityBoundary(),
                        if (_room.isBusiness) const SizedBox(height: 18),
                        _metrics(),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final desktop = constraints.maxWidth >= 820;
                            final overview = _overview();
                            final team = _team(bundle.members);
                            return desktop
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: overview),
                                      const SizedBox(width: 18),
                                      Expanded(flex: 2, child: team),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      overview,
                                      const SizedBox(height: 18),
                                      team,
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 24),
                        _checklist(bundle.tasks),
                        const SizedBox(height: 24),
                        if (!_room.isBusiness &&
                            (_room.ownedByCurrentUser ||
                                _room.sharingPreferences['documents'] ==
                                    true)) ...[
                          _documents(bundle.documents),
                          const SizedBox(height: 24),
                        ],
                        _notes(bundle.notes),
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
  );

  Widget _roomHeader(DealRoomBundle bundle) => Container(
    color: _ink,
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
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const DwellingIqLogo(size: 44),
                  ),
                  const Spacer(),
                  if (MediaQuery.sizeOf(context).width >= 700) ...[
                    PlatformSwitcher(
                      selected: _room.isBusiness
                          ? PlatformSide.business
                          : PlatformSide.property,
                      onChanged: (side) =>
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => PlatformHubPage(side: side),
                            ),
                          ),
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_back, size: 17),
                    label: const Text('ALL DEAL ROOMS'),
                  ),
                ],
              ),
              if (MediaQuery.sizeOf(context).width < 700) ...[
                const SizedBox(height: 12),
                PlatformSwitcher(
                  selected: _room.isBusiness
                      ? PlatformSide.business
                      : PlatformSide.property,
                  onChanged: (side) => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => PlatformHubPage(side: side),
                    ),
                  ),
                  compact: true,
                ),
              ],
              const SizedBox(height: 52),
              Text(
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
              Text(
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
              Text(
                '${_room.status.toUpperCase().replaceAll('_', ' ')} · ${bundle.members.length} TEAM MEMBER${bundle.members.length == 1 ? '' : 'S'}',
                style: const TextStyle(color: Color(0xFFBCAEFF), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
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
                  symbol: r'$',
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
                  name: 'CAD',
                  decimalDigits: 0,
                ).format(
                  (_room.riskSnapshot['cash_after_owner_salary'] as num?)
                          ?.toDouble() ??
                      0,
                )
              : monthly == null
              ? '—'
              : NumberFormat.simpleCurrency(
                  name: 'CAD',
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
          child: Text(
            'CONFIDENTIAL DOCUMENT VAULT DISABLED · Use this workspace for summarized figures, tasks and non-sensitive notes only. Sensitive M&A uploads will remain blocked until mandatory MFA, malware scanning, audit logs, watermarks and expiring downloads are operational and independently tested.',
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
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
        TextField(
          controller: _goals,
          enabled: _room.ownedByCurrentUser,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Goals and decision context',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _timeline,
          enabled: _room.ownedByCurrentUser,
          decoration: const InputDecoration(
            labelText: 'Timeline or target closing date',
          ),
        ),
        if (_room.ownedByCurrentUser) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _room.status,
                  decoration: const InputDecoration(labelText: 'Deal stage'),
                  items:
                      const [
                            'draft',
                            'active',
                            'under_offer',
                            'closing',
                            'completed',
                            'archived',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
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
                onPressed: _saving ? null : () => _saveRoom(_room.status),
                child: const Text('SAVE'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
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
            title: const Text('Share financial model'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _room.sharingPreferences['risk'] != false,
            onChanged: (value) => _setSharing('risk', value),
            title: const Text('Share risk assessment'),
            contentPadding: EdgeInsets.zero,
          ),
          if (!_room.isBusiness)
            SwitchListTile(
              value: _room.sharingPreferences['documents'] == true,
              onChanged: (value) => _setSharing('documents', value),
              title: const Text('Allow document access'),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ],
    ),
  );

  Widget _team(List<DealRoomMember> members) => _card(
    _room.isBusiness ? 'Acquisition team' : 'Property team',
    members.isEmpty
        ? const Text(
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
                          Text(
                            provider.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
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
                            child: Text('Accept workspace'),
                          ),
                          PopupMenuItem(value: false, child: Text('Decline')),
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
                            child: Text('Summary access'),
                          ),
                          PopupMenuItem(
                            value: 'standard',
                            child: Text('Standard access'),
                          ),
                          PopupMenuItem(
                            value: 'full',
                            child: Text('Full access'),
                          ),
                        ],
                        child: Text(
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

  Widget _checklist(List<DealRoomTask> tasks) {
    final complete = tasks.where((task) => task.completed).length;
    return _card(
      'Transaction checklist · $complete/${tasks.length}',
      Column(
        children: tasks
            .map(
              (task) => CheckboxListTile(
                value: task.completed,
                onChanged: (value) async {
                  await DealRoomService.toggleTask(task, value ?? false);
                  _refresh();
                },
                title: Text(task.title),
                subtitle: Text(task.category.toUpperCase()),
                contentPadding: EdgeInsets.zero,
                activeColor: _purple,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            )
            .toList(),
      ),
    );
  }

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
                  labelText: 'Add a decision, question or update',
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
            child: Text('No shared notes yet.'),
          )
        else
          ...notes.map(
            (note) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: note.mine ? const Color(0xFFEDE9FE) : _paper,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.text, style: const TextStyle(height: 1.45)),
                  const SizedBox(height: 6),
                  Text(
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

  Widget _documents(List<DealRoomDocument> documents) => _card(
    'Documents',
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
          label: Text(_uploading ? 'UPLOADING…' : 'UPLOAD DOCUMENT'),
        ),
        const SizedBox(height: 14),
        if (documents.isEmpty)
          const Text(
            'No shared documents yet. Upload PDFs, images or Word documents up to 15 MB.',
            style: TextStyle(color: Color(0xFF666674), fontSize: 12),
          )
        else
          ...documents.map(
            (document) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, color: _purple),
              title: Text(document.fileName),
              subtitle: Text(
                '${(document.fileSize / 1024).ceil()} KB · ${DateFormat.MMMd().format(document.createdAt)}',
              ),
            ),
          ),
      ],
    ),
  );

  Widget _card(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE3E3E9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
