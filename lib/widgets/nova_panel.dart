import 'package:flutter/material.dart';
import '../services/nova_service.dart';
import '../services/nova_training_controller.dart';
import 'nova_character.dart';
import 'site_copy_text.dart';

/// A quiet, on-demand replay control. The one-time introduction lives at the
/// app root, so changing pages cannot reset or repeat the guide.
class NovaPanel extends StatelessWidget {
  const NovaPanel({
    super.key,
    required this.context,
    this.contextProvider,
    this.tourRole,
    this.onTourNavigate,
    this.initiallyOpen = false,
  });
  final NovaContext context;
  final NovaContext Function()? contextProvider;
  final String? tourRole;
  final void Function(String)? onTourNavigate;
  final bool initiallyOpen;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextButton.icon(
      onPressed: () => NovaTrainingController.instance.start(
        role:
            tourRole ??
            switch (this.context.area) {
              'seller' => 'seller',
              'member' => 'member',
              _ => 'buyer',
            },
      ),
      icon: const NovaCharacter(size: 32),
      label: const SiteCopyText(
        'nova.training.replay',
        'Show me around with Pebble',
      ),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF164F3D)),
    ),
  );
}
