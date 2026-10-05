import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/nova_walkthrough.dart';

/// Render one pose directly from the supplied transparent atlas, without altering
/// the original artwork or creating look-alike replacement assets.
class NovaCharacter extends StatefulWidget {
  const NovaCharacter({
    super.key,
    this.mood = NovaMood.welcome,
    this.size = 104,
  });
  final NovaMood mood;
  final double size;
  @override
  State<NovaCharacter> createState() => _NovaCharacterState();
}

class _NovaCharacterState extends State<NovaCharacter> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    _stream = const AssetImage(
      'assets/images/nova-character-atlas.png',
    ).resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, _) {
      if (mounted)
        setState(() {
          _info?.dispose();
          _info = info;
        });
    });
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pebble, ${widget.mood.name}',
    image: true,
    child: SizedBox.square(
      dimension: widget.size,
      child: _info == null
          ? const Icon(Icons.eco_outlined, color: Color(0xFF48643A))
          : CustomPaint(painter: _NovaPosePainter(_info!.image, widget.mood)),
    ),
  );
}

class _NovaPosePainter extends CustomPainter {
  const _NovaPosePainter(this.image, this.mood);
  final ui.Image image;
  final NovaMood mood;
  @override
  void paint(Canvas canvas, Size size) {
    final crop = switch (mood) {
      NovaMood.welcome => const Rect.fromLTWH(25, 20, 651, 877),
      NovaMood.studying => const Rect.fromLTWH(705, 22, 549, 509),
      NovaMood.planning => const Rect.fromLTWH(741, 532, 495, 394),
      NovaMood.curious => const Rect.fromLTWH(26, 925, 414, 329),
      NovaMood.reassuring => const Rect.fromLTWH(459, 892, 360, 362),
      NovaMood.celebrating => const Rect.fromLTWH(846, 918, 382, 336),
    };
    final scale = (size.width / crop.width < size.height / crop.height)
        ? size.width / crop.width
        : size.height / crop.height;
    final width = crop.width * scale, height = crop.height * scale;
    canvas.drawImageRect(
      image,
      crop,
      Rect.fromLTWH(
        (size.width - width) / 2,
        (size.height - height) / 2,
        width,
        height,
      ),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_NovaPosePainter old) =>
      image != old.image || mood != old.mood;
}
