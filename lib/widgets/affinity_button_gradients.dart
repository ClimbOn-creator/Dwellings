import 'package:flutter/material.dart';

/// Paints inside the button's Material, preserving its shape, ink and hit target.
class AffinityButtonGradients {
  static ThemeData apply(ThemeData base) {
    const gradient = ButtonStyle(backgroundBuilder: _background);
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.merge(gradient) ?? gradient,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.merge(gradient) ?? gradient,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.merge(gradient) ?? gradient,
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.merge(gradient) ?? gradient,
      ),
    );
  }

  static Widget _background(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) => _ButtonGradient(states: states, child: child ?? const SizedBox.shrink());
}

class _ButtonGradient extends StatelessWidget {
  const _ButtonGradient({required this.states, required this.child});
  final Set<WidgetState> states;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // This layer is below the button's own Material, so these are the actual
    // resolved colours, including local styles, tonal variants and disabled UI.
    final material = context.findAncestorWidgetOfExactType<Material>();
    final source = material?.color;
    if (source == null ||
        source.a < .85 ||
        states.contains(WidgetState.disabled)) {
      return child;
    }
    final hsv = HSVColor.fromColor(source);
    final green = hsv.hue >= 70 && hsv.hue <= 185 && hsv.saturation > .16;
    final black = hsv.value < .16 || (hsv.saturation < .23 && hsv.value < .38);
    if (!green && !black) return child;
    final darkLabel =
        (material?.textStyle?.color?.computeLuminance() ?? 1) < .3;
    final colors = green
        ? darkLabel
              ? const [Color(0xFFADC39A), Color(0xFFC0C784)]
              : const [Color(0xFF164F3D), Color(0xFF65733F)]
        : const [Color(0xFF151A18), Color(0xFF5A605C)];
    final active =
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: active ? 1 : 0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      child: child,
      builder: (context, progress, content) => Ink(
        decoration: ShapeDecoration(
          shape: material?.shape ?? const RoundedRectangleBorder(),
          gradient: LinearGradient(
            // Move a two-width gradient by one button width. Both ends retain
            // their colour contrast throughout the slide; it never goes flat.
            begin: Alignment(-1 - 2 * progress, 0),
            end: Alignment(3 - 2 * progress, 0),
            colors: [colors[0], colors[1], colors[0]],
          ),
        ),
        child: content,
      ),
    );
  }
}
