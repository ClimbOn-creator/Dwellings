import 'package:flutter/material.dart';
import '../services/nova_service.dart';

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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
