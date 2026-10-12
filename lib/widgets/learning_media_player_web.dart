import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class LearningMediaPlayer extends StatefulWidget {
  const LearningMediaPlayer({super.key, required this.url, this.audio = false});
  final String url;
  final bool audio;
  @override
  State<LearningMediaPlayer> createState() => _LearningMediaPlayerState();
}

class _LearningMediaPlayerState extends State<LearningMediaPlayer> {
  static int sequence = 0;
  late String id;
  web.HTMLMediaElement? element;
  @override
  void initState() {
    super.initState();
    id = 'learning-media-${sequence++}';
    ui.platformViewRegistry.registerViewFactory(id, (_) {
      final e = widget.audio ? web.HTMLAudioElement() : web.HTMLVideoElement();
      e.src = widget.url;
      e.controls = true;
      e.preload = 'metadata';
      e.style.width = '100%';
      e.style.height = '100%';
      e.style.objectFit = 'contain';
      element = e;
      return e;
    });
  }

  @override
  void didUpdateWidget(covariant LearningMediaPlayer old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) element?.src = widget.url;
  }

  @override
  void dispose() {
    element?.pause();
    element?.src = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.audio ? 64 : 300,
    child: HtmlElementView(viewType: id),
  );
}
