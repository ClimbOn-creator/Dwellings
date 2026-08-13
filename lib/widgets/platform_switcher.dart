import 'package:flutter/material.dart';

import '../models/platform_side.dart';

class PlatformSwitcher extends StatelessWidget {
  const PlatformSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.micro = false,
  });

  final PlatformSide? selected;
  final ValueChanged<PlatformSide> onChanged;
  final bool compact;
  final bool micro;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(micro ? 3 : 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: PlatformSide.values
          .map(
            (side) => InkWell(
              onTap: () => onChanged(side),
              borderRadius: BorderRadius.circular(19),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(
                  horizontal: micro ? 7 : (compact ? 12 : 16),
                  vertical: micro ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: selected == side ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Text(
                  compact ? side.shortLabel : side.label.toUpperCase(),
                  style: TextStyle(
                    color: selected == side
                        ? const Color(0xFF050510)
                        : Colors.white70,
                    fontSize: micro ? 8 : 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
