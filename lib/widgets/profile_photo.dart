import 'package:flutter/material.dart';

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.size,
    this.photoUrl = '',
    this.exampleIndex,
    this.borderRadius,
  });

  final double size;
  final String photoUrl;
  final int? exampleIndex;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : exampleIndex != null
            ? _ExampleSprite(index: exampleIndex!, size: size)
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFFE8E4F8),
    alignment: Alignment.center,
    child: Icon(Icons.person, color: const Color(0xFF252525), size: size * .48),
  );
}

class _ExampleSprite extends StatelessWidget {
  const _ExampleSprite({required this.index, required this.size});
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, 9);
    final column = safeIndex % 5;
    final row = safeIndex ~/ 5;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: size * 5,
        maxWidth: size * 5,
        minHeight: size * 2,
        maxHeight: size * 2,
        child: Transform.translate(
          offset: Offset(-column * size, -row * size),
          child: Image.asset(
            'assets/images/example-professionals-grid.png',
            width: size * 5,
            height: size * 2,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
