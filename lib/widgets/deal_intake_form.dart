import 'package:flutter/material.dart';
import '../services/deal_intake_fields.dart';
import 'site_copy_text.dart';

class DealIntakeForm extends StatelessWidget {
  const DealIntakeForm({
    super.key,
    required this.controllers,
    this.stage,
    this.enabled = true,
  });
  final Map<String, TextEditingController> controllers;
  final int? stage;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final f in dealIntakeFields.where(
        (f) => stage == null || f.stage == stage,
      ))
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: controllers[f.key],
            enabled: enabled,
            minLines: 1,
            maxLines: f.key == 'currency' ? 1 : 3,
            textCapitalization: f.key == 'currency'
                ? TextCapitalization.characters
                : TextCapitalization.sentences,
            decoration: InputDecoration(
              label: SiteCopyText('intake.${f.key}.label', f.label),
              helper: SiteCopyText(
                'intake.${f.key}.hint',
                f.hint,
                style: const TextStyle(fontSize: 12, color: Color(0xFF555564)),
              ),
              helperMaxLines: 4,
            ),
          ),
        ),
    ],
  );
}
