import 'package:flutter/material.dart';

/// Gives desktop layouts the same room as an 80% browser zoom without changing
/// the browser's own zoom or the user's accessibility text settings.
class AppDisplayScale extends StatelessWidget {
  const AppDisplayScale({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep phone and narrow tablet controls at their normal touch size.
        final scale = constraints.maxWidth >= 900 ? 0.8 : 1.0;
        if (scale == 1.0) return child;
        final media = MediaQuery.of(context);
        final size = Size(
          constraints.maxWidth / scale,
          constraints.maxHeight / scale,
        );
        return FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: size,
            child: MediaQuery(
              data: media.copyWith(
                size: size,
                padding: media.padding / scale,
                viewPadding: media.viewPadding / scale,
                viewInsets: media.viewInsets / scale,
                systemGestureInsets: media.systemGestureInsets / scale,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
