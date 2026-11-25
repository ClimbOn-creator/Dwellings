import 'package:flutter/material.dart';

import '../models/learning_track_content.dart';
import 'site_copy_text.dart';

/// Each track and section has independent permanent published content slots.
class LearningTrackLesson extends StatelessWidget {
  const LearningTrackLesson({
    super.key,
    required this.track,
    required this.section,
    required this.videoOnLeft,
  });

  final LearningTrack track;
  final String section;
  final bool videoOnLeft;

  String get _prefix => 'learning.track.${track.name}.$section';

  Widget _copy(String key, {TextStyle? style}) =>
      SiteCopyText(key, learningTrackCopy[key]!, style: style);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: _pane(video: videoOnLeft)),
      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8E2D8)),
      Expanded(child: _pane(video: !videoOnLeft)),
    ],
  );

  Widget _pane({required bool video}) => ColoredBox(
    key: ValueKey(video ? 'learning-video-pane' : 'learning-text-pane'),
    color: video ? const Color(0xFFF6F4EF) : Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE8E2D8))),
          ),
          child: Row(
            children: [
              Icon(
                video ? Icons.videocam_outlined : Icons.description_outlined,
                color: const Color(0xFF6A6051),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SiteCopyText(
                  video
                      ? 'learning.lesson.shared.videoPane'
                      : 'learning.lesson.shared.textPane',
                  video ? 'Video' : 'Text',
                  style: const TextStyle(
                    color: Color(0xFF514A3E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('$_prefix.${video ? 'video' : 'text'}'),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copy(
                  'learning.track.${track.name}.label',
                  style: const TextStyle(
                    color: Color(0xFF56625D),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _copy(
                  '$_prefix.title',
                  style: const TextStyle(
                    color: Color(0xFF173A27),
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                if (video) ...[
                  const Icon(
                    Icons.play_circle_outline,
                    size: 48,
                    color: Color(0xFF56625D),
                  ),
                  const SizedBox(height: 16),
                  _copy(
                    'learning.track.video.pending',
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ] else
                  _copy(
                    '$_prefix.body',
                    style: const TextStyle(
                      color: Color(0xFF242824),
                      fontSize: 16,
                      height: 1.65,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
