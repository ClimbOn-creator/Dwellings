import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/buyer_command_state.dart';
import '../services/deal_room_service.dart';
import 'dashboard_ui.dart';
import 'site_copy_text.dart';

/// Small secondary cards that follow the existing pipeline and team widgets.
class BuyerDashboardFollowUp extends StatelessWidget {
  const BuyerDashboardFollowUp({
    super.key,
    required this.rooms,
    required this.bundles,
    required this.now,
    required this.onOpenDeal,
    required this.onOpenPlan,
    this.lastRoomId,
    this.loading = false,
    this.error = false,
  });
  final List<DealRoom> rooms;
  final List<DealRoomBundle> bundles;
  final DateTime now;
  final String? lastRoomId;
  final bool loading, error;
  final ValueChanged<DealRoom> onOpenDeal, onOpenPlan;
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
  Widget _resume(AcquisitionCommand? deal) => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copy(
          'continue.heading',
          'Continue where you left off',
          size: 18,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
          size: 18,
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
        for (final event in events.take(3))
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
    if (state.resume == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 740;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: narrow ? box.maxWidth : (box.maxWidth - 12) / 2,
              child: _resume(state.resume),
            ),
            SizedBox(
              width: narrow ? box.maxWidth : (box.maxWidth - 12) / 2,
              child: _upcoming(state.events),
            ),
          ],
        );
      },
    );
  }
}
