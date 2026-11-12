import 'package:flutter/material.dart';
import 'site_copy_text.dart';

class LearningBlankLesson extends StatelessWidget {
  const LearningBlankLesson({super.key, required this.videoOnLeft});

  final bool videoOnLeft;

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
        const Expanded(child: SizedBox.expand()),
      ],
    ),
  );
}
