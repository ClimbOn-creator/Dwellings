import 'package:flutter/material.dart';

class AmbientVideo extends StatelessWidget {
  const AmbientVideo({
    super.key,
    required this.url,
    required this.poster,
    required this.paused,
  });
  final String url, poster;
  final bool paused;
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
