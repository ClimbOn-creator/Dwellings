import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Silent looping background footage plays automatically while visible.
class AmbientVideo extends StatefulWidget {
  const AmbientVideo({
    super.key,
    required this.url,
    required this.poster,
    required this.paused,
  });
  final String url, poster;
  final bool paused;
  @override
  State<AmbientVideo> createState() => _AmbientVideoState();
}

class _AmbientVideoState extends State<AmbientVideo> {
  static int _sequence = 0;
  late final String _id;
  web.HTMLVideoElement? _video;
  web.IntersectionObserver? _observer;
  bool _visible = false;
  void _sync() {
    final video = _video;
    if (video == null) return;
    if (_visible && !widget.paused) {
      video.play().toDart.then((_) {}, onError: (Object _) {});
    } else {
      video.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    _id = 'pact-ambient-${_sequence++}';
    ui.platformViewRegistry.registerViewFactory(_id, (_) {
      final video = web.HTMLVideoElement()
        ..src = widget.url
        ..poster = widget.poster
        ..autoplay = true
        ..muted = true
        ..loop = true
        ..playsInline = true
        ..controls = false
        ..preload = 'auto';
      video.setAttribute('muted', '');
      video.setAttribute('autoplay', '');
      video.setAttribute('loop', '');
      video.setAttribute('playsinline', '');
      video.setAttribute('aria-hidden', 'true');
      video.tabIndex = -1;
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';
      video.style.pointerEvents = 'none';
      _video = video;
      _observer = web.IntersectionObserver(
        ((
              JSArray<web.IntersectionObserverEntry> entries,
              web.IntersectionObserver observer,
            ) {
              if (!mounted) return;
              _visible = entries.toDart.any((entry) => entry.isIntersecting);
              _sync();
            })
            .toJS,
      );
      _observer!.observe(video);
      return video;
    });
  }

  @override
  void didUpdateWidget(covariant AmbientVideo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _video?.src = widget.url;
      _video?.poster = widget.poster;
    }
    _sync();
  }

  @override
  void dispose() {
    _observer?.disconnect();
    _video?.pause();
    _video?.src = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: HtmlElementView(viewType: _id));
}
