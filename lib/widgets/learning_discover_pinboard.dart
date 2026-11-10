import 'package:flutter/material.dart';

const _notes = [
  Color(0xffead481),
  Color(0xffe8b7a8),
  Color(0xffc2d0ac),
  Color(0xffb5cad3),
  Color(0xffe9d3a7),
  Color(0xffd3c4dc),
  Color(0xffebdb99),
];

class DiscoverPinboard extends StatelessWidget {
  const DiscoverPinboard({super.key, this.openNote});
  final ValueChanged<int>? openNote;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.6,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xffb88f66),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xff75503a), width: 8),
        ),
        boxShadow: [BoxShadow(color: Color(0x3332261c), offset: Offset(5, 6))],
      ),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final w = bounds.maxWidth;
          final h = bounds.maxHeight;
          final noteWidth = w * .19;
          final noteHeight = h * .33;
          return Stack(
            children: [
              for (var i = 0; i < _notes.length; i++)
                Positioned(
                  left: i < 4
                      ? w * (.065 + i * .23)
                      : w * (.18 + (i - 4) * .245),
                  top: h * (i < 4 ? .15 : .56),
                  width: noteWidth,
                  height: noteHeight,
                  child: Transform.rotate(
                    angle: const [-.09, .06, -.045, .075, .05, -.065, .08][i],
                    child: Material(
                      color: _notes[i],
                      elevation: 2,
                      child: InkWell(
                        onTap: openNote == null ? null : () => openNote!(i),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const Alignment(0, -.86),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Color(0xff923a36),
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.square(dimension: h * .035),
                              ),
                            ),
                            if (openNote != null)
                              Center(
                                child: Text(
                                  'Note ${i + 1}',
                                  style: TextStyle(
                                    color: const Color(0xff4d3829),
                                    fontSize: noteWidth * .17,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class DiscoverPinboardPage extends StatelessWidget {
  const DiscoverPinboardPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff4eee4),
    appBar: AppBar(
      backgroundColor: const Color(0xfff4eee4),
      leading: const BackButton(),
      title: const Text('Discover pinboard'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: DiscoverPinboard(
            openNote: (index) => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: _notes[index],
                child: SizedBox(
                  width: 440,
                  height: 320,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Note ${index + 1}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close note',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
