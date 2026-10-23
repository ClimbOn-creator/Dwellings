import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/acquisition_journey.dart';
import '../models/learning_journey.dart';
import '../services/backend_service.dart';
import '../services/learning_service.dart';
import '../services/transaction_learning.dart';
import 'site_copy_text.dart';
import 'transaction_room_panel.dart';

class AcquisitionJourneyPanel extends StatefulWidget {
  const AcquisitionJourneyPanel({super.key, required this.onOpenDocument});
  final ValueChanged<String> onOpenDocument;
  @override
  State<AcquisitionJourneyPanel> createState() =>
      _AcquisitionJourneyPanelState();
}

class _AcquisitionJourneyPanelState extends State<AcquisitionJourneyPanel> {
  int selected = 0;
  int? answer;
  Set<String> completed = {};
  bool saving = false;
  int revision = 0;
  String? notice;
  StreamSubscription? auth;
  AcquisitionJourneyStage get stage => acquisitionJourneyStages[selected];
  String get progressKey => stage.phaseId;
  @override
  void initState() {
    super.initState();
    _load();
    auth = BackendService.authChanges?.listen((_) {
      if (!mounted) return;
      revision++;
      setState(() {
        completed = {};
        answer = null;
        notice = null;
        saving = false;
      });
      _load();
    });
  }

  @override
  void dispose() {
    auth?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final token = ++revision;
    final uid = BackendService.user?.id;
    final prefs = await SharedPreferences.getInstance();
    var values =
        (prefs.getStringList('learning.progress.${uid ?? 'guest'}') ?? [])
            .toSet();
    String? message;
    if (uid != null) {
      try {
        values = await LearningService.progress();
      } catch (_) {
        message =
            'Showing this device’s progress. Account sync is unavailable.';
      }
    }
    if (mounted && token == revision && uid == BackendService.user?.id)
      setState(() {
        completed = values;
        notice = message;
      });
  }

  Future<void> _mark() async {
    if (saving) return;
    final uid = BackendService.user?.id;
    final id = progressKey;
    final complete = !completed.contains(id);
    if (complete && answer != stage.phase.correct) return;
    revision++;
    setState(() => saving = true);
    final values = {...completed};
    if (complete) {
      values.add(id);
    } else {
      values.remove(id);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (uid != BackendService.user?.id) return;
      await prefs.setStringList(
        'learning.progress.${uid ?? 'guest'}',
        values.toList(),
      );
      if (!mounted || uid != BackendService.user?.id) return;
      setState(() => completed = values);
      if (uid != null) await LearningService.markConcept(id, complete);
      if (mounted && uid == BackendService.user?.id)
        setState(
          () => notice = uid == null
              ? 'Progress saved on this device. Sign in to sync across devices.'
              : 'Progress saved to your account.',
        );
    } catch (_) {
      if (mounted && uid == BackendService.user?.id)
        setState(
          () => notice =
              'Account sync failed. Your device keeps its saved progress; try again when connected.',
        );
    } finally {
      if (mounted && uid == BackendService.user?.id)
        setState(() => saving = false);
    }
  }

  Widget text(String field, String fallback, {TextStyle? style}) =>
      SiteCopyText(
        ['explanation', 'why', 'action', 'question', 'feedback'].contains(field)
            ? 'learning.map.${stage.phaseId}.$field'
            : 'learning.journey.${stage.id}.$field',
        fallback,
        style: style ?? const TextStyle(color: learningInk, height: 1.55),
      );
  @override
  Widget build(BuildContext context) {
    final phase = stage.phase;
    final document = transactionLessons.firstWhere(
      (l) => l.id == stage.documentIds.first,
    );
    final count = acquisitionJourneyStages
        .where((s) => completed.contains(s.phaseId))
        .length;
    final done = completed.contains(progressKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SiteCopyText(
          'learning.journey.kicker',
          'LEARN BY WORKING THROUGH A DEAL',
          style: TextStyle(
            color: learningViolet,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const SiteCopyText(
          'learning.journey.title',
          'Acquisition Journey',
          style: TextStyle(
            color: learningInk,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        const SiteCopyText(
          'learning.journey.intro',
          'Five stages. One clearer path to ownership. Learn the concepts, explore a fictional example, and practise the next decision.',
          style: TextStyle(color: learningMuted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        learningCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count of 5 stages understood',
                style: const TextStyle(
                  color: learningInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: count / 5,
                  minHeight: 7,
                  color: learningViolet,
                  backgroundColor: const Color(0xFFEEEAFF),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Practice progress is separate from your real Transaction Plan.',
                style: TextStyle(color: learningMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < acquisitionJourneyStages.length; i++)
                SizedBox(
                  width: box.maxWidth >= 1000
                      ? (box.maxWidth - 40) / 5
                      : box.maxWidth >= 600
                      ? (box.maxWidth - 10) / 2
                      : box.maxWidth,
                  child: Material(
                    color: selected == i ? learningViolet : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      key: ValueKey('journey-stage-$i'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() {
                        selected = i;
                        answer = null;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              completed.contains(
                                    acquisitionJourneyStages[i].phaseId,
                                  )
                                  ? Icons.check_circle_outline
                                  : Icons.radio_button_unchecked,
                              size: 19,
                              color: selected == i
                                  ? Colors.white
                                  : learningViolet,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '${i + 1}. ${acquisitionJourneyStages[i].title}',
                                style: TextStyle(
                                  color: selected == i
                                      ? Colors.white
                                      : learningInk,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
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
          ),
        ),
        const SizedBox(height: 24),
        learningCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STAGE ${selected + 1} OF 5 · ABOUT 5 MIN',
                style: const TextStyle(
                  color: learningViolet,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              text(
                'title',
                stage.title,
                style: const TextStyle(
                  color: learningInk,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              text(
                'subtitle',
                stage.subtitle,
                style: const TextStyle(color: learningMuted, fontSize: 15),
              ),
              const SizedBox(height: 24),
              text('explanation', phase.explanation),
              if (selected == 4) ...[
                const SizedBox(height: 12),
                text(
                  'funding',
                  buyerLearningJourney
                      .firstWhere((p) => p.id == 'buyer-finance')
                      .explanation,
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Why this matters',
                style: TextStyle(
                  color: learningInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              text('why', phase.why),
              const SizedBox(height: 20),
              const Text(
                'Your next move',
                style: TextStyle(
                  color: learningInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              text('action', phase.action),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A FICTIONAL DEAL',
                      style: TextStyle(
                        color: learningViolet,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    text('example', document.example),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'What would you do?',
                style: TextStyle(
                  color: learningInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              text('question', phase.question),
              const SizedBox(height: 12),
              for (var i = 0; i < phase.choices.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: answer == i
                        ? const Color(0xFFEEEAFF)
                        : const Color(0xFFF8F8FA),
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      key: ValueKey('journey-answer-$i'),
                      onTap: () => setState(() => answer = i),
                      leading: Icon(
                        answer == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: learningViolet,
                      ),
                      title: text('choice.$i', phase.choices[i]),
                    ),
                  ),
                ),
              if (answer != null) ...[
                const SizedBox(height: 10),
                Text(
                  answer == phase.correct
                      ? 'That’s right.'
                      : 'Try another approach.',
                  style: TextStyle(
                    color: answer == phase.correct
                        ? const Color(0xFF24745D)
                        : const Color(0xFFAC4E69),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                text('feedback', phase.feedback),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    key: const Key('journey-mark-understood'),
                    onPressed: saving || (!done && answer != phase.correct)
                        ? null
                        : _mark,
                    icon: Icon(done ? Icons.check_circle : Icons.check),
                    style: FilledButton.styleFrom(
                      backgroundColor: learningViolet,
                    ),
                    label: Text(
                      done ? 'Understood · undo' : 'Mark stage understood',
                    ),
                  ),
                  if (selected < 4)
                    TextButton(
                      onPressed: () => setState(() {
                        selected++;
                        answer = null;
                      }),
                      child: const Text('Next stage →'),
                    ),
                ],
              ),
              if (notice != null) ...[
                const SizedBox(height: 12),
                Text(
                  notice!,
                  style: const TextStyle(color: learningMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Documents for this stage',
                style: TextStyle(
                  color: learningInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              for (final id in stage.documentIds)
                TextButton.icon(
                  onPressed: () => widget.onOpenDocument(id),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(
                    transactionLessons.firstWhere((l) => l.id == id).title,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
