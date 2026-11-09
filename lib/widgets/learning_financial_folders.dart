import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/site_copy_catalog.dart';
import '../services/site_content_service.dart';
import 'site_copy_text.dart';

const _manila = Color(0xFFF3EBD9);
const _seam = Color(0xFFCDBD9F);

const _leftFolders = [
  (id: 'statements', color: Color(0xFF9BBCAF)),
  (id: 'earnings', color: Color(0xFF9EBBD8)),
  (id: 'working-capital', color: Color(0xFFE9A886)),
  (id: 'financing', color: Color(0xFFE4C978)),
  (id: 'cash-flow', color: Color(0xFFDCA0A4)),
];

const _rightFolders = [
  (id: 'revenue', color: Color(0xFFB8AED6)),
  (id: 'expenses', color: Color(0xFF9AC9C7)),
  (id: 'balance-sheet', color: Color(0xFFAFC58C)),
  (id: 'forecasts', color: Color(0xFFECB59D)),
  (id: 'capital-spending', color: Color(0xFFD7A6C5)),
];

typedef _Folder = ({String id, Color color});

String _titleKey(_Folder folder) => 'learning.financial.${folder.id}.title';

String _title(_Folder folder) => SiteContentService.text(
  _titleKey(folder),
  siteCopyCatalog[_titleKey(folder)]!,
);

class LearningFinancialFolders extends StatelessWidget {
  const LearningFinancialFolders({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 16, 8, 40),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1500),
        child: LayoutBuilder(
          builder: (context, box) {
            const gap = 40.0;
            final sideBySide = box.maxWidth >= 860;
            final stackWidth = math.min(
              730.0,
              sideBySide ? (box.maxWidth - gap) / 2 : box.maxWidth,
            );
            return Wrap(
              spacing: gap,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _FolderStack(folders: _leftFolders, width: stackWidth),
                _FolderStack(folders: _rightFolders, width: stackWidth),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _FolderStack extends StatelessWidget {
  const _FolderStack({required this.folders, required this.width});

  final List<_Folder> folders;
  final double width;

  @override
  Widget build(BuildContext context) {
    final compact = width < 480;
    final horizontalStep = compact ? 9.0 : 17.0;
    final verticalStep = compact ? 42.0 : 47.0;
    final folderWidth = width - horizontalStep * (folders.length - 1);
    final height = (folderWidth * .54).clamp(155.0, 322.0);
    return SizedBox(
      width: width,
      height: height + verticalStep * (folders.length - 1) + 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < folders.length; i++)
            Positioned(
              key: ValueKey('financial-layer-${folders[i].id}'),
              left: i * horizontalStep,
              top: 12 + i * verticalStep,
              width: folderWidth,
              height: height,
              child: _ClosedFolder(
                folder: folders[i],
                tabOffset: 12 + i * folderWidth * .105,
                onOpen: () => showDialog<void>(
                  context: context,
                  builder: (_) => _OpenedFolder(folder: folders[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClosedFolder extends StatefulWidget {
  const _ClosedFolder({
    required this.folder,
    required this.tabOffset,
    required this.onOpen,
  });

  final _Folder folder;
  final double tabOffset;
  final VoidCallback onOpen;

  @override
  State<_ClosedFolder> createState() => _ClosedFolderState();
}

class _ClosedFolderState extends State<_ClosedFolder> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final tabWidth = math.min(160.0, box.maxWidth - widget.tabOffset - 8);
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('financial-lift-${widget.folder.id}'),
          tween: Tween(end: _hovered || _focused ? -7 : 0),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          builder: (context, lift, child) => Transform.translate(
            offset: Offset(0, lift),
            transformHitTests: false,
            child: child,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('financial-folder-${widget.folder.id}'),
              onTap: widget.onOpen,
              onFocusChange: (focused) => setState(() => _focused = focused),
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 33,
                    bottom: 0,
                    child: _FolderCover(focused: _focused),
                  ),
                  Positioned(
                    left: widget.tabOffset,
                    top: 0,
                    width: tabWidth,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.folder.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Center(
                          child: SiteCopyText(
                            _titleKey(widget.folder),
                            siteCopyCatalog[_titleKey(widget.folder)]!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _FolderCover extends StatelessWidget {
  const _FolderCover({this.focused = false});

  final bool focused;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _manila,
      border: Border.all(color: focused ? const Color(0xFF52452F) : _seam),
      borderRadius: BorderRadius.circular(9),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24000000),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
  );
}

class _OpenedFolder extends StatelessWidget {
  const _OpenedFolder({required this.folder});

  final _Folder folder;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: LayoutBuilder(
        builder: (context, box) {
          final height = math.min(
            box.maxHeight,
            (box.maxWidth * .73).clamp(215.0, 350.0),
          );
          return SizedBox(
            width: box.maxWidth,
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 620),
              curve: Curves.easeInOutCubic,
              builder: (context, progress, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: height * .27,
                    child: const _FolderCover(),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    top: height * (.29 - progress * .22),
                    bottom: 17,
                    child: Opacity(
                      opacity: progress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E2DB)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 52, 12),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              _title(folder),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: height * .67,
                    child: Transform(
                      key: const Key('financial-open-flap'),
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .0011)
                        ..rotateX(progress * 1.16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const _FolderCover(),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(14, 8, 0, 0),
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: folder.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 2,
                    child: IconButton.filledTonal(
                      tooltip: 'Close folder',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF202020),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 19),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
