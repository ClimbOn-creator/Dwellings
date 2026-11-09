import 'package:flutter/material.dart';

import '../models/acquisition_journey.dart';
import '../services/site_copy_catalog.dart';
import 'site_copy_text.dart';
import 'transaction_room_panel.dart';

class AcquisitionJourneyPanel extends StatefulWidget {
  const AcquisitionJourneyPanel({super.key, this.initialStageId});

  final String? initialStageId;

  @override
  State<AcquisitionJourneyPanel> createState() =>
      _AcquisitionJourneyPanelState();
}

class _AcquisitionJourneyPanelState extends State<AcquisitionJourneyPanel> {
  String? _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialStageId;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SiteCopyText(
        'learning.journey.title',
        'Roadmap',
        style: TextStyle(
          color: learningInk,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 24),
      for (var i = 0; i < acquisitionJourneyStages.length; i++)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: _section(i)),
    ],
  );

  Widget _section(int index) {
    final item = acquisitionJourneyStages[index];
    final expanded = _expanded == item.id;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: learningLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              key: ValueKey('journey-stage-$index'),
              onTap: () =>
                  setState(() => _expanded = expanded ? null : item.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        color: learningMuted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SiteCopyText(
                        'learning.journey.${item.id}.title',
                        item.title,
                        style: const TextStyle(
                          color: learningInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? .5 : 0,
                      duration: duration,
                      curve: Curves.easeInOut,
                      child: const Icon(Icons.keyboard_arrow_down, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        child: SiteCopyText(
                          'learning.journey.${item.id}.body',
                          learningRoadmapPlaceholder,
                          style: const TextStyle(
                            color: learningInk,
                            fontSize: 16,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
