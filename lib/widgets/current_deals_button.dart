import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../screens/auth_page.dart';
import '../screens/deal_rooms_page.dart';
import '../services/backend_service.dart';

class CurrentDealsButton extends StatelessWidget {
  const CurrentDealsButton({
    super.key,
    required this.side,
    this.dark = true,
    this.compact = false,
  });

  final PlatformSide side;
  final bool dark;
  final bool compact;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackendService.user == null
            ? const AuthPage()
            : DealRoomsPage(initialSide: side),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => _open(context),
    style: TextButton.styleFrom(
      foregroundColor: dark ? Colors.white : const Color(0xFF050510),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    icon: const Icon(Icons.track_changes_outlined, size: 17),
    label: Text(
      compact ? 'DEALS' : 'CURRENT DEALS',
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .55,
      ),
    ),
  );
}
