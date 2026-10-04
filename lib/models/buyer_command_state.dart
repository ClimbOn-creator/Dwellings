import '../services/deal_room_service.dart';

bool isActiveAcquisition(DealRoom room) =>
    !{'archived', 'completed', 'cancelled'}.contains(room.status);
String acquisitionStage(String stage) => switch (stage) {
  'discovery' || 'sourcing' => 'Sourcing',
  'screening' || 'evaluation' => 'Evaluation',
  'financing' || 'finance' => 'Financing',
  'offer' => 'Offer / LOI',
  'diligence' => 'Due diligence',
  'legal' => 'Legal review',
  'closing' => 'Closing',
  'handover' || 'transition' => 'Transition',
  _ => 'Review stage',
};

enum AcquisitionHealth { attention, dueSoon, onTrack, awaitingDetails }

class AcquisitionCommand {
  AcquisitionCommand(this.room, this.bundle, this.now);
  final DealRoom room;
  final DealRoomBundle? bundle;
  final DateTime now;
  List<DealRoomTask> get pending =>
      bundle?.tasks.where((task) => !task.completed).toList() ?? [];
  bool overdue(DateTime? date) =>
      date != null &&
      date.toLocal().isBefore(DateTime(now.year, now.month, now.day));
  bool dueSoon(DateTime? date) =>
      date != null &&
      date.toLocal().isBefore(DateTime(now.year, now.month, now.day + 8));
  int get attentionCount =>
      pending.where((task) => task.blocked || overdue(task.dueAt)).length +
      (overdue(room.targetCloseDate) ? 1 : 0);
  AcquisitionHealth get health {
    if (attentionCount > 0 ||
        (bundle == null &&
            (room.blockedTaskCount > 0 || overdue(room.nextDueAt))) ||
        overdue(room.targetCloseDate))
      return AcquisitionHealth.attention;
    if (pending.any((task) => dueSoon(task.dueAt)) ||
        (bundle == null && dueSoon(room.nextDueAt)) ||
        dueSoon(room.targetCloseDate))
      return AcquisitionHealth.dueSoon;
    if (bundle == null || bundle!.tasks.isEmpty)
      return AcquisitionHealth.awaitingDetails;
    return AcquisitionHealth.onTrack;
  }

  DealRoomTask? get nextTask {
    final tasks = pending;
    int priority(DealRoomTask task) => task.blocked
        ? 0
        : overdue(task.dueAt)
        ? 1
        : dueSoon(task.dueAt)
        ? 2
        : task.status == 'in_progress'
        ? 3
        : task.stage == room.currentStage
        ? 4
        : 5;
    tasks.sort((a, b) {
      final difference = priority(a).compareTo(priority(b));
      if (difference != 0) return difference;
      if (a.dueAt != null && b.dueAt != null) {
        final due = a.dueAt!.compareTo(b.dueAt!);
        if (due != 0) return due;
      }
      return a.position.compareTo(b.position);
    });
    return tasks.firstOrNull;
  }

  String get nextAction =>
      nextTask?.title ??
      (bundle != null && bundle!.tasks.isNotEmpty
          ? 'Review completed checklist'
          : room.currentStep);
  (String, double)? get progress {
    if (bundle == null)
      return room.totalTaskCount == 0
          ? null
          : ('Checklist', room.progress.clamp(0, 1));
    final stage = bundle!.tasks
        .where((task) => task.stage == room.currentStage)
        .toList();
    final tasks = stage.isEmpty ? bundle!.tasks : stage;
    if (tasks.isEmpty) return null;
    return (
      stage.isEmpty ? 'Checklist' : acquisitionStage(room.currentStage),
      tasks.where((task) => task.completed).length / tasks.length,
    );
  }
}

class AcquisitionEvent {
  const AcquisitionEvent(
    this.room,
    this.title,
    this.date, {
    this.closing = false,
  });
  final DealRoom room;
  final String title;
  final DateTime date;
  final bool closing;
}

class BuyerCommandState {
  BuyerCommandState(
    List<DealRoom> rooms,
    List<DealRoomBundle> bundles,
    DateTime now, {
    String? lastRoomId,
  }) {
    final byId = {for (final bundle in bundles) bundle.room.id: bundle};
    deals = rooms
        .where(isActiveAcquisition)
        .map((room) => AcquisitionCommand(room, byId[room.id], now))
        .toList();
    final recent = [...deals]
      ..sort((a, b) => b.room.updatedAt.compareTo(a.room.updatedAt));
    resume =
        deals.where((deal) => deal.room.id == lastRoomId).firstOrNull ??
        recent.firstOrNull;
    events = [
      for (final deal in deals) ...[
        for (final task in deal.pending)
          if (task.dueAt != null)
            AcquisitionEvent(deal.room, task.title, task.dueAt!),
        if (deal.room.targetCloseDate != null)
          AcquisitionEvent(
            deal.room,
            'Target closing',
            deal.room.targetCloseDate!,
            closing: true,
          ),
      ],
    ]..sort((a, b) => a.date.compareTo(b.date));
  }
  late final List<AcquisitionCommand> deals;
  late final AcquisitionCommand? resume;
  late final List<AcquisitionEvent> events;
  int get attentionCount =>
      deals.fold(0, (total, deal) => total + deal.attentionCount);
}
