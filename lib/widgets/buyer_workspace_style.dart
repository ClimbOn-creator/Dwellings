import 'package:flutter/material.dart';

/// Quiet, monochrome presentation for the buyer workspace and public resources.
class BuyerWorkspaceStyle {
  static const ink = Color(0xFF292929);
  static const blue = Color(0xFF202020);
  static const muted = Color(0xFF787878);
  static const line = Color(0xFFE8E8E8);
  static const canvas = Color(0xFFFFFFFF);
  static const paleBlue = Color(0xFFFAFAFA);
  static const paleGreen = Color(0xFFFAFAFA);
  static const paleGold = Color(0xFFFAFAFA);
  static const paleViolet = Color(0xFFFAFAFA);

  static ThemeData theme(ThemeData base) => base.copyWith(
    colorScheme: const ColorScheme.light(primary: blue, surface: Colors.white),
    scaffoldBackgroundColor: Colors.white,
    dividerColor: line,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontFamily: 'PactInter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ).copyWith(backgroundBuilder: (_, _, child) => child!),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ).copyWith(backgroundBuilder: (_, _, child) => child!),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
      ).copyWith(backgroundBuilder: (_, _, child) => child!),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFF2F2F2),
      side: const BorderSide(color: line),
      showCheckmark: false,
      labelStyle: const TextStyle(
        fontFamily: 'PactInter',
        color: ink,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      hintStyle: const TextStyle(color: muted, fontSize: 14),
      prefixIconColor: muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: muted),
      ),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'PactInter',
      bodyColor: ink,
      displayColor: ink,
    ),
  );

  static Widget panel({required Widget child, EdgeInsets? padding}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(8),
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
      color: Colors.white,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(8),
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
            Icon(icon, color: muted, size: 23),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          note,
          style: TextStyle(
            fontSize: 11,
            color: muted,
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
    VoidCallback onTap, {
    bool dark = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Material(
      color: selected
          ? (dark ? const Color(0xFF303033) : const Color(0xFFF2F2F2))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: dark
                    ? (selected ? Colors.white : Colors.white60)
                    : (selected ? blue : muted),
              ),
              const SizedBox(width: 13),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: dark ? Colors.white : (selected ? blue : ink),
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
          fontWeight: FontWeight.w600,
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
