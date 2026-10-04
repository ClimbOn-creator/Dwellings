import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/buyer_command_state.dart';
import '../services/deal_room_service.dart';
import 'dashboard_ui.dart';
import 'site_copy_text.dart';

class BuyerCommandCentre extends StatelessWidget {
  const BuyerCommandCentre({
    super.key,
    required this.rooms,
    required this.bundles,
    required this.now,
    required this.greeting,
    required this.onOpenDeal,
    required this.onOpenPlan,
    required this.onRetry,
    required this.search,
    this.name = '',
    this.lastRoomId,
    this.loading = false,
    this.error = false,
    this.filter = '',
  });
  final List<DealRoom> rooms;
  final List<DealRoomBundle> bundles;
  final DateTime now;
  final String greeting, name, filter;
  final String? lastRoomId;
  final bool loading, error;
  final ValueChanged<DealRoom> onOpenDeal, onOpenPlan;
  final VoidCallback onRetry;
  final Widget search;
  Widget _copy(
    String id,
    String text, {
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = DashboardUi.ink,
  }) => SiteCopyText(
    'buyer.command.$id',
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    ),
  );

  Widget _health(AcquisitionHealth health) {
    final (label, color) = switch (health) {
      AcquisitionHealth.attention => (
        'Needs attention',
        const Color(0xFFB34035),
      ),
      AcquisitionHealth.dueSoon => ('Due soon', const Color(0xFF9D6C09)),
      AcquisitionHealth.onTrack => ('On track', const Color(0xFF27704C)),
      AcquisitionHealth.awaitingDetails => ('Check plan', DashboardUi.muted),
    };
    return Tooltip(
      message: switch (health) {
        AcquisitionHealth.attention =>
          'A task is blocked or a scheduled deadline is overdue.',
        AcquisitionHealth.dueSoon =>
          'A scheduled deadline is within the next seven days.',
        AcquisitionHealth.onTrack =>
          'No blocked tasks or approaching deadlines are recorded.',
        AcquisitionHealth.awaitingDetails =>
          'Task details or a checklist are needed to assess this deal.',
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AcquisitionCommand deal, bool narrow) {
    final name = TextButton(
      onPressed: () => onOpenDeal(deal.room),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.zero,
      ),
      child: Text(
        deal.room.title,
        style: const TextStyle(
          color: DashboardUi.ink,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
    final action = TextButton(
      onPressed: () => onOpenPlan(deal.room),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(deal.nextAction, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 7),
          const Icon(Icons.arrow_forward, size: 16),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DashboardUi.line)),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                name,
                Text(
                  acquisitionStage(deal.room.currentStage),
                  style: const TextStyle(
                    color: DashboardUi.muted,
                    fontSize: 13,
                  ),
                ),
                action,
                _health(deal.health),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: name),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Text(
                    acquisitionStage(deal.room.currentStage),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: action),
                const SizedBox(width: 16),
                SizedBox(width: 120, child: _health(deal.health)),
              ],
            ),
    );
  }

  Widget _resume(AcquisitionCommand? deal) => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copy(
          'continue.heading',
          'Continue where you left off',
          size: 20,
          weight: FontWeight.w700,
        ),
        const SizedBox(height: 18),
        if (deal == null)
          _copy(
            'continue.empty',
            'Your next acquisition starts here. Search businesses or enter a private deal below.',
            color: DashboardUi.muted,
          )
        else ...[
          Text(
            deal.room.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          if (deal.progress case final progress?) ...[
            Text(
              '${progress.$1} ${(progress.$2 * 100).round()}% complete',
              style: const TextStyle(color: DashboardUi.muted),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.$2,
              borderRadius: BorderRadius.circular(5),
              minHeight: 6,
              backgroundColor: DashboardUi.paleBlue,
            ),
          ] else
            _copy(
              'continue.noChecklist',
              'Open the deal to set up its next steps.',
              color: DashboardUi.muted,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('continue-acquisition'),
            onPressed: () => onOpenDeal(deal.room),
            label: _copy(
              'continue.button',
              'Continue Deal',
              color: Colors.white,
              weight: FontWeight.w600,
            ),
            icon: const Icon(Icons.arrow_forward, size: 18),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ],
    ),
  );

  Widget _upcoming(List<AcquisitionEvent> events) => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copy(
          'upcoming.heading',
          'Upcoming',
          size: 20,
          weight: FontWeight.w700,
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          _copy(
            'upcoming.empty',
            loading
                ? 'Loading scheduled actions…'
                : error
                ? 'Scheduled actions are temporarily unavailable.'
                : 'No deadlines scheduled. Add dates in a deal’s Transaction Plan.',
            color: DashboardUi.muted,
          ),
        for (final event in events.take(5))
          TextButton(
            onPressed: () => onOpenPlan(event.room),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.event_outlined, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: DashboardUi.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        event.room.title,
                        style: const TextStyle(
                          color: DashboardUi.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${DateFormat(event.date.year == now.year ? 'EEE, MMM d' : 'EEE, MMM d, y').format(event.date.toLocal())}${event.date.toLocal().isBefore(DateTime(now.year, now.month, now.day)) ? ' · Overdue' : ''}',
                        style: const TextStyle(
                          color: DashboardUi.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = BuyerCommandState(
      rooms,
      bundles,
      now,
      lastRoomId: lastRoomId,
    );
    final shown = state.deals
        .where(
          (deal) =>
              deal.room.title.toLowerCase().contains(filter.toLowerCase()) ||
              deal.room.city.toLowerCase().contains(filter.toLowerCase()),
        )
        .toList();
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 780;
        final headline = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting${name.trim().isEmpty ? '' : ', ${name.trim().split(RegExp(r'\s+')).first}'}',
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${state.deals.length} active ${state.deals.length == 1 ? 'acquisition' : 'acquisitions'} · ${loading
                  ? 'Updating actions…'
                  : error
                  ? 'Action details unavailable'
                  : '${state.attentionCount} ${state.attentionCount == 1 ? 'action needs' : 'actions need'} attention'}',
              style: const TextStyle(color: DashboardUi.muted, fontSize: 15),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (narrow) ...[
              headline,
              const SizedBox(height: 18),
              search,
            ] else
              Row(
                children: [
                  Expanded(child: headline),
                  const SizedBox(width: 20),
                  SizedBox(width: 255, child: search),
                ],
              ),
            const SizedBox(height: 25),
            if (error)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _copy(
                        'error',
                        'Could not load task details. Your deals are still available.',
                        color: DashboardUi.muted,
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: _copy('retry', 'Retry'),
                    ),
                  ],
                ),
              ),
            DashboardUi.panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _copy(
                    'deals.heading',
                    'Your acquisitions',
                    size: 20,
                    weight: FontWeight.w700,
                  ),
                  const SizedBox(height: 8),
                  _copy(
                    'deals.subtitle',
                    'The next step for every active deal.',
                    color: DashboardUi.muted,
                  ),
                  const SizedBox(height: 16),
                  if (shown.isEmpty)
                    _copy(
                      'deals.empty',
                      state.deals.isEmpty
                          ? 'No active acquisitions yet. Add a deal below to start your workspace.'
                          : 'No acquisitions match your search.',
                      color: DashboardUi.muted,
                    ),
                  if (!narrow && shown.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _copy(
                              'table.deal',
                              'Deal',
                              size: 12,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _copy(
                              'table.stage',
                              'Stage',
                              size: 12,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: _copy(
                              'table.action',
                              'Next action',
                              size: 12,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: _copy(
                              'table.health',
                              'Health',
                              size: 12,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final deal in shown) _row(deal, narrow),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (narrow) ...[
              _resume(state.resume),
              const SizedBox(height: 18),
              _upcoming(state.events),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _resume(state.resume)),
                  const SizedBox(width: 18),
                  Expanded(child: _upcoming(state.events)),
                ],
              ),
          ],
        );
      },
    );
  }
}
