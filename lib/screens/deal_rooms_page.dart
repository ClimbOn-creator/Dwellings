import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/deal_room_service.dart';
import '../services/member_deal_marketplace_service.dart';
import '../services/site_content_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/topo_background.dart';
import '../widgets/profile_photo.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/acquisition_editorial_header.dart';
import '../widgets/membership_footer.dart';
import '../widgets/fixed_editorial_background.dart';
import 'acquisition_support_page.dart';
import 'business_acquisition_page.dart';
import 'auth_page.dart';

const _ink = Color(0xFF171717);
const _paper = Color(0xFFF4F1EB);
const _purple = Color(0xFF053827);
const _lilac = Color(0xFF9B9B98);
const _surface = Color(0xFFFCFBF8);
const _line = Color(0xFFD6D1C9);

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
  bool _showAll = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    _rooms = DealRoomService.loadRooms();
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

  Future<void> _manualCreate() async {
    final result = await showDialog<_NewDealDetails>(
      context: context,
      builder: (_) => _NewDealDialog(
        initialKind: _side == PlatformSide.business
            ? 'business'
            : 'residential',
      ),
    );
    if (result == null) return;
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
      );
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => DealRoomPage(room: room)));
      final foundation = await AcquisitionFoundation.load();
      await foundation.saveForAccount('pipeline');
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create deal: $error')),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
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
          toolbarHeight: 78,
          backgroundColor: const Color(0xFFF7F5F0),
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          title: const HomeBrandButton(size: 58, dark: false),
          actions: const [
            AppNavigationMenu(side: PlatformSide.business, dark: false),
            SizedBox(width: 12),
          ],
        ),
        body: FixedEditorialBackground(
          imagePath: 'assets/images/affinity-pipeline.jpg',
          wash: _paper,
          washOpacity: .32,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 90),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AcquisitionEditorialHeader(
                            currentStep: 3,
                            onSelected: _goStep,
                            kicker: 'PAGE 4 OF 4 · PIPELINE',
                            title: SiteContentService.text(
                              'pipeline.title',
                              'My Deal Pipeline',
                            ),
                            subtitle: SiteContentService.text(
                              'pipeline.subtitle',
                              'Keep every opportunity, decision, deadline, and blocker in one focused acquisition workspace.',
                            ),
                            accent: Color(0xFF244E43),
                          ),
                          const SizedBox(height: 38),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: _creating ? null : _manualCreate,
                                icon: const Icon(Icons.add),
                                label: const Text('START A NEW DEAL'),
                              ),
                              FilterChip(
                                label: Text(
                                  _showArchived ? 'PAST / ARCHIVED' : 'CURRENT',
                                ),
                                selected: _showArchived,
                                backgroundColor: _surface,
                                selectedColor: _purple,
                                checkmarkColor: Colors.white,
                                labelStyle: const TextStyle(color: _ink),
                                onSelected: (value) =>
                                    setState(() => _showArchived = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          FutureBuilder<List<DealRoom>>(
                            future: _rooms,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                  height: 260,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final allRooms = snapshot.data!;
                              final rooms = allRooms.where((room) {
                                final lifecycleMatch = _showArchived
                                    ? room.status == 'archived' ||
                                          room.status == 'completed' ||
                                          room.status == 'cancelled'
                                    : room.status != 'archived' &&
                                          room.status != 'completed' &&
                                          room.status != 'cancelled';
                                final sideMatch = room.isBusiness;
                                return lifecycleMatch && sideMatch;
                              }).toList();
                              if (rooms.isEmpty) return _empty();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _summary(allRooms),
                                  const SizedBox(height: 26),
                                  Text(
                                    '${rooms.length} ${_showArchived ? 'PAST' : 'CURRENT'} DEAL${rooms.length == 1 ? '' : 'S'}',
                                    style: const TextStyle(
                                      color: _lilac,
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
                        ],
                      ),
                    ),
                  ),
                ),
                const MembershipFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                Text(
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
                Text(
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
                  child: Text(
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
                      label: Text(_creating ? 'CREATING…' : 'START A NEW DEAL'),
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
                        label: const Text('USE LATEST ANALYSIS'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('ALL DEALS'),
                      selected: _showAll,
                      onSelected: (_) => setState(() => _showAll = true),
                    ),
                    ChoiceChip(
                      label: Text(
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
        Text(
          _showArchived ? 'No past deals yet' : 'No current deals yet',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _showArchived
              ? 'Completed, cancelled and archived transactions will remain available here.'
              : 'Start a business acquisition and its guided checklist will be created automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFA5A5B5)),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _creating ? null : _manualCreate,
          child: const Text('START A NEW DEAL'),
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
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            Text(
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
                    Text(
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
                Text(
                  [
                    if (room.city.isNotEmpty) room.city,
                    if (room.purchasePrice > 0)
                      NumberFormat.simpleCurrency(
                        name: 'CAD',
                        decimalDigits: 0,
                      ).format(room.purchasePrice),
                    'Updated ${DateFormat.MMMd().format(room.updatedAt)}',
                    if (room.targetCloseDate != null)
                      'Target ${DateFormat.MMMd().format(room.targetCloseDate!)}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: Color(0xFFA5A5B5),
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
                  '${room.currentStage.toUpperCase()} · ${room.currentStep.toUpperCase()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .45,
                  ),
                ),
                if (room.blockedTaskCount > 0) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${room.blockedTaskCount} BLOCKER${room.blockedTaskCount == 1 ? '' : 'S'} NEED ATTENTION',
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

class _NewDealDetails {
  const _NewDealDetails({
    required this.title,
    required this.kind,
    required this.location,
    required this.purchasePrice,
    required this.goals,
    required this.targetCloseDate,
  });
  final String title;
  final String kind;
  final String location;
  final double purchasePrice;
  final String goals;
  final DateTime? targetCloseDate;
}

class _NewDealDialog extends StatefulWidget {
  const _NewDealDialog({required this.initialKind});
  final String initialKind;

  @override
  State<_NewDealDialog> createState() => _NewDealDialogState();
}

class _NewDealDialogState extends State<_NewDealDialog> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _goals = TextEditingController();
  late String _kind;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _price.dispose();
    _goals.dispose();
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
    if (_title.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      _NewDealDetails(
        title: _title.text.trim(),
        kind: _kind,
        location: _location.text.trim(),
        purchasePrice:
            double.tryParse(_price.text.replaceAll(',', '').trim()) ?? 0,
        goals: _goals.text.trim(),
        targetCloseDate: _targetDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _surface,
    surfaceTintColor: Colors.transparent,
    title: const Text(
      'Start a new acquisition',
      style: TextStyle(color: Colors.white),
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text('Business acquisition')),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: _kind == 'business'
                    ? 'Business or opportunity name'
                    : 'Property or deal name',
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Address, city or market',
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expected purchase price (CAD)',
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _goals,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Goals and important context',
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _targetDate == null
                      ? 'ADD TARGET CLOSING DATE'
                      : 'TARGET ${DateFormat.yMMMd().format(_targetDate!)}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${DealRoomService.templatesFor(_kind).length} guided tasks will be created across ${DealRoomService.stagesFor(_kind).length} transaction stages.',
              style: const TextStyle(color: Color(0xFF666674), fontSize: 11),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(onPressed: _submit, child: const Text('CREATE DEAL')),
    ],
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
    title: Text(widget.task.title),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.task.details.isNotEmpty)
              Text(
                widget.task.details,
                style: const TextStyle(color: Color(0xFF666674), height: 1.45),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Task status'),
              items: const [
                DropdownMenuItem(
                  value: 'not_started',
                  child: Text('Not started'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In progress'),
                ),
                DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _assignedProviderId,
              decoration: const InputDecoration(labelText: 'Assigned to'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Unassigned / deal owner'),
                ),
                ...widget.members.map(
                  (member) => DropdownMenuItem<String?>(
                    value: member.provider.id,
                    child: Text(member.provider.name),
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
                label: Text(
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
                  labelText: 'What is blocking this task?',
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
        child: const Text('CANCEL'),
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
        child: const Text('SAVE TASK'),
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

enum _DealWorkspaceView { overview, plan, vault, team }

class _DealRoomPageState extends State<DealRoomPage> {
  late DealRoom _room;
  late Future<DealRoomBundle> _bundle;
  final _note = TextEditingController();
  final _timeline = TextEditingController();
  final _goals = TextEditingController();
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
    _timeline.text = _room.timeline;
    _goals.text = _room.goals;
    _targetDate = _room.targetCloseDate;
    _bundle = DealRoomService.loadBundle(_room);
    _introductions = MemberDealMarketplaceService.loadBuyerResponses();
  }

  @override
  void dispose() {
    _note.dispose();
    _timeline.dispose();
    _goals.dispose();
    super.dispose();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
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
              child: Text(
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
        Text(
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
        _railButton(
          _DealWorkspaceView.overview,
          Icons.space_dashboard_outlined,
          'Overview',
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
        _railButton(_DealWorkspaceView.team, Icons.groups_2_outlined, 'Team'),
        const Spacer(),
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
              Text(
                _workspaceLabel.toUpperCase(),
                style: const TextStyle(
                  color: _purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
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
    _DealWorkspaceView.plan => 'Guided execution',
    _DealWorkspaceView.vault => 'Secure records',
    _DealWorkspaceView.team => 'People and decisions',
  };

  String get _workspaceTitle => switch (_workspaceView) {
    _DealWorkspaceView.overview => 'Overview',
    _DealWorkspaceView.plan => 'Transaction plan',
    _DealWorkspaceView.vault => 'Document vault',
    _DealWorkspaceView.team => 'Deal team',
  };

  Widget _headerFact(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
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
        _overview(),
      ],
    ),
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
  };

  Widget _restrictedVault() => _card(
    'Private document vault',
    const Text(
      'The buyer has not enabled document access for this workspace.',
      style: TextStyle(color: _lilac),
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
        child: Text(
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
                  Text(
                    'Introductions',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
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
        child: const Text(
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
        Text(
          'No introductions yet',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
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
        Text(
          'Buyer identity protected',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
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
              child: Text(
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
                  Text(
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
                  Text(
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
          Text(
            pitch.offerSummary,
            style: const TextStyle(
              color: _purple,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
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
                  child: const Text('PASS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _respondToIntroduction(pitch, 'accepted'),
                  child: const Text('CONNECT'),
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
    child: Text(
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
            content: Text(
              status == 'accepted'
                  ? 'Introduction accepted. Your contact details are now shared.'
                  : 'Introduction passed.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
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
      NavigationBar(
        selectedIndex: _workspaceView.index,
        backgroundColor: const Color(0xFFF8F6F1),
        indicatorColor: const Color(0xFFE5EEE9),
        onDestinationSelected: (index) =>
            setState(() => _workspaceView = _DealWorkspaceView.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            label: 'Team',
          ),
        ],
      ),
    ],
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
                  '${_room.dealKind.toUpperCase()} · ${_room.currentStage.toUpperCase().replaceAll('_', ' ')} · ${bundle.members.length} TEAM MEMBER${bundle.members.length == 1 ? '' : 'S'}',
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
                const Text(
                  'NEXT ACTION',
                  style: TextStyle(
                    color: _lilac,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
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
      Text(
        value,
        style: TextStyle(
          color: alert ? const Color(0xFFFF8177) : Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
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
        const SizedBox(height: 12),
        if (_room.ownedByCurrentUser)
          DropdownButtonFormField<String>(
            initialValue: _room.currentStage,
            decoration: const InputDecoration(labelText: 'Current step'),
            items: DealRoomService.stagesFor(_room.dealKind)
                .map(
                  (stage) => DropdownMenuItem(
                    value: stage,
                    child: Text(stage.toUpperCase().replaceAll('_', ' ')),
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
              label: Text(
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
                  decoration: const InputDecoration(labelText: 'Deal stage'),
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
              Text(
                '$complete/${tasks.length} COMPLETE',
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
              child: Text(
                '$blocked BLOCKED TASK${blocked == 1 ? '' : 'S'} · Resolve these before the transaction can move cleanly.',
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
        title: Text(
          stage.toUpperCase().replaceAll('_', ' '),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: current ? _purple : _ink,
            letterSpacing: .8,
          ),
        ),
        subtitle: Text('$complete/${tasks.length} complete'),
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
        color: task.blocked ? const Color(0xFF321C26) : const Color(0xFF1A1A2E),
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
                  Text(
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
                    Text(
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
                    Text(
                      'BLOCKER · ${task.blockerNote}',
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
      color: alert ? const Color(0xFF4A2027) : _purple.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
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
                color: note.mine
                    ? _purple.withValues(alpha: .14)
                    : const Color(0xFF1A1A2E),
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
          label: Text(_uploading ? 'UPLOADING…' : 'UPLOAD DOCUMENT'),
        ),
        const SizedBox(height: 14),
        const Text(
          'PDF, JPG or PNG · 15 MB maximum · authenticated participants only',
          style: TextStyle(color: Color(0xFF666674), fontSize: 11),
        ),
        const SizedBox(height: 14),
        if (documents.isEmpty)
          const Text(
            'No private documents have been added.',
            style: TextStyle(color: Color(0xFF666674), fontSize: 12),
          )
        else
          ...documents.map(
            (document) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, color: _purple),
              title: Text(document.fileName),
              subtitle: Text(
                '${(document.fileSize / 1024).ceil()} KB · ${document.securityStatus.toUpperCase()} · ${DateFormat.MMMd().format(document.createdAt)}',
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$error')));
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Download securely'),
                  ),
                  if (_room.ownedByCurrentUser ||
                      document.uploadedBy == BackendService.user?.id)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete document'),
                    ),
                ],
              ),
            ),
          ),
        if (events.isNotEmpty) ...[
          const Divider(height: 32),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'File activity',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Recent downloads, uploads and deletions'),
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
                    title: Text(
                      '${event.eventType.toUpperCase()} · ${event.fileName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
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
