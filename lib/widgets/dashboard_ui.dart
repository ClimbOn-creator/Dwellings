import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared visual language for the buyer and member workspaces.
class DashboardUi {
  static const ink = Color(0xFF17243B);
  static const blue = Color(0xFF2757A5);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE3EAF3);
  static const canvas = Color(0xFFF7FAFF);
  static const paleBlue = Color(0xFFEAF2FF);
  static const paleGreen = Color(0xFFE9F8F0);
  static const paleGold = Color(0xFFFFF5E5);
  static const paleViolet = Color(0xFFF0EFFF);

  static ThemeData theme(ThemeData base) => base.copyWith(
    colorScheme: const ColorScheme.light(primary: blue, surface: Colors.white),
    textTheme: GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: ink, displayColor: ink),
  );

  static Widget panel({required Widget child, EdgeInsets? padding}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A315783),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: padding ?? const EdgeInsets.all(18),
        child: child,
      );

  static Widget metric(
    String label,
    String value,
    String note,
    IconData icon,
    Color color,
    Color iconColor,
  ) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(icon, color: iconColor, size: 23),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          note,
          style: TextStyle(
            fontSize: 11,
            color: iconColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  static Widget nav(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Material(
      color: selected ? const Color(0xFFE5EDFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 19, color: selected ? blue : muted),
              const SizedBox(width: 13),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? blue : ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  static Widget sectionTitle(String title, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    ],
  );
}
