import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LearningMediaPlayer extends StatelessWidget {
  const LearningMediaPlayer({
    super.key,
    required this.url,
    this.audio = false,
    this.poster,
  });
  final String url;
  final bool audio;
  final String? poster;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    icon: Icon(audio ? Icons.audiotrack : Icons.play_circle_outline),
    label: const Text('Open media'),
  );
}
