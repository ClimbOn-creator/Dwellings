import 'dart:ui' as ui;
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/site_content_service.dart';

/// Kept outside routes so editor mode follows every page and modal.
class SiteEditorShell extends StatefulWidget {
  const SiteEditorShell({super.key, required this.child});
  final Widget child;
  @override
  State<SiteEditorShell> createState() => _SiteEditorShellState();
}

class _SiteEditorShellState extends State<SiteEditorShell> {
  StreamSubscription<dynamic>? _auth;
  Timer? _refresh;
  int _request = 0;
  bool _allowed = false;
  @override
  void initState() {
    super.initState();
    _check();
    _auth = BackendService.authChanges?.listen((_) {
      if (BackendService.user == null) {
        SiteContentService.editing.value = false;
        if (mounted) setState(() => _allowed = false);
      }
      _check();
    });
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) async {
      await SiteContentService.initialize();
      await _check();
    });
  }

  Future<void> _check() async {
    final request = ++_request;
    final allowed = await SiteContentService.canEdit();
    if (!mounted || request != _request) return;
    if (!allowed) SiteContentService.editing.value = false;
    setState(() => _allowed = allowed);
  }

  @override
  void dispose() {
    _request++;
    _auth?.cancel();
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: widget.child),
      if (_allowed)
        Positioned(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
          right: 12,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            child: ValueListenableBuilder<bool>(
              valueListenable: SiteContentService.editing,
              builder: (context, editing, _) => Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          SiteContentService.editing.value = !editing,
                      icon: Icon(editing ? Icons.check : Icons.edit_outlined),
                      label: Text(editing ? 'Done editing' : 'Edit this page'),
                    ),
                    if (editing)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.touch_app_outlined,
                          semanticLabel: 'Click text or a picture, then Edit',
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
}

class SiteEditTarget extends StatelessWidget {
  const SiteEditTarget({
    super.key,
    required this.contentKey,
    required this.fallback,
    required this.child,
    this.image = false,
  });
  final String contentKey;
  final String fallback;
  final Widget child;
  final bool image;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) {
      if (!editing) return child;
      final target =
          !image && SiteContentService.text(contentKey, fallback).isEmpty
          ? const Text('Empty text · click to edit')
          : child;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              selectSiteContent(context, contentKey, fallback, image: image),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3578DD)),
            ),
            child: target,
          ),
        ),
      );
    },
  );
}

Future<void> selectSiteContent(
  BuildContext context,
  String key,
  String fallback, {
  bool image = false,
}) async {
  final edit = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(image ? 'Selected picture' : 'Selected text'),
      content: image
          ? const Text('Replace this picture with an image from your device.')
          : Text(
              SiteContentService.text(key, fallback),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
      ],
    ),
  );
  if (edit != true || !context.mounted || !SiteContentService.editing.value)
    return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _ContentDialog(contentKey: key, fallback: fallback, image: image),
  );
}

class _ContentDialog extends StatefulWidget {
  const _ContentDialog({
    required this.contentKey,
    required this.fallback,
    required this.image,
  });
  final String contentKey;
  final String fallback;
  final bool image;
  @override
  State<_ContentDialog> createState() => _ContentDialogState();
}

class _ContentDialogState extends State<_ContentDialog> {
  late final TextEditingController _text;
  late final String? _expected;
  PlatformFile? _file;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _expected = SiteContentService.published(widget.contentKey);
    _text = TextEditingController(
      text: SiteContentService.text(widget.contentKey, widget.fallback),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (!mounted || result == null) return;
      final file = result.files.single;
      SiteContentService.validateImage(file.bytes, file.extension ?? '');
      final codec = await ui.instantiateImageCodec(
        file.bytes!,
        targetWidth: 512,
      );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (!mounted) return;
      setState(() {
        _file = file;
        _error = null;
      });
    } catch (_) {
      if (mounted)
        setState(
          () =>
              _error = 'Choose a JPG, PNG or WebP picture smaller than 10 MB.',
        );
    }
  }

  Future<void> _save({bool reset = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    String? uploaded;
    try {
      if (!await SiteContentService.canEdit())
        throw StateError('Sign in again with an editor account.');
      if (reset) {
        await SiteContentService.reset(widget.contentKey, expected: _expected);
      } else {
        var value = _text.text;
        if (widget.image) {
          if (_file == null)
            throw StateError('Choose a replacement picture first.');
          uploaded = await SiteContentService.uploadImage(
            _file!.bytes!,
            _file!.extension!,
          );
          value = uploaded;
        }
        await SiteContentService.saveExpected(
          widget.contentKey,
          value,
          expected: _expected,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (uploaded != null) await SiteContentService.discardUpload(uploaded);
      if (SiteContentService.isConflict(error))
        await SiteContentService.initialize();
      if (mounted)
        setState(
          () => _error =
              'Could not save. Your changes are still here. ${SiteContentService.saveError(error)}',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.image ? 'Replace picture' : 'Edit text'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Saving publishes this change for everyone.'),
              if (widget.fallback.contains('{{value'))
                const Text(
                  'Keep {{value1}}, {{value2}}, and other placeholders where the app should insert live values.',
                ),
              const SizedBox(height: 16),
              if (widget.image) ...[
                if (_file?.bytes != null)
                  Image.memory(
                    _file!.bytes!,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text(
                      'This image could not be previewed. Choose another file.',
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.upload),
                  label: Text(_file?.name ?? 'Upload a picture'),
                ),
                const Text('JPG, PNG or WebP · up to 10 MB'),
              ] else
                TextField(
                  controller: _text,
                  enabled: !_busy,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 12,
                  maxLength: 12000,
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    alignLabelWithHint: true,
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (_expected != null)
          TextButton(
            onPressed: _busy ? null : () => _save(reset: true),
            child: const Text('Restore original'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || (widget.image && _file == null) ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}

/// Existing records keep their own access checks and persistence paths.
class SiteRecordEditTarget extends StatelessWidget {
  const SiteRecordEditTarget({
    super.key,
    required this.child,
    required this.onEdit,
    this.label = 'listing',
  });
  final Widget child;
  final Future<void> Function() onEdit;
  final String label;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) => !editing
        ? child
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final edit = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Selected $label'),
                  content: Text('Edit this $label using its own editor.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              );
              if (edit == true &&
                  context.mounted &&
                  SiteContentService.editing.value)
                await onEdit();
            },
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3578DD)),
              ),
              child: child,
            ),
          ),
  );
}
