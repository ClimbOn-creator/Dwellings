import 'dart:async';

import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/site_content_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import 'auth_page.dart';

class ContentStudioPage extends StatefulWidget {
  const ContentStudioPage({super.key});

  @override
  State<ContentStudioPage> createState() => _ContentStudioPageState();
}

class _ContentStudioPageState extends State<ContentStudioPage> {
  final _controllers = <String, TextEditingController>{};
  final _timers = <String, Timer>{};
  final _states = <String, String>{};
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    for (final section in SiteContentService.sections.values) {
      for (final entry in section.entries) {
        _controllers[entry.key] = TextEditingController(
          text: SiteContentService.text(entry.key, entry.value),
        );
      }
    }
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final allowed = await SiteContentService.canEdit();
    if (mounted)
      setState(() {
        _allowed = allowed;
        _loading = false;
      });
  }

  void _queueSave(String key, String value) {
    _timers[key]?.cancel();
    setState(() => _states[key] = 'Editing…');
    _timers[key] = Timer(const Duration(milliseconds: 650), () async {
      if (mounted) setState(() => _states[key] = 'Saving…');
      try {
        await SiteContentService.save(key, value);
        if (mounted) setState(() => _states[key] = 'Saved');
      } catch (_) {
        if (mounted) setState(() => _states[key] = 'Could not save');
      }
    });
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F3EF),
    appBar: AppBar(
      toolbarHeight: 76,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 14),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : !_allowed
        ? _locked()
        : _editor(),
  );

  Widget _locked() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 42),
            const SizedBox(height: 18),
            const Text(
              'Content Studio is private',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Only the two approved Affinity editors can change published site copy.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            if (BackendService.user == null)
              FilledButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AuthPage()),
                  );
                  await _checkAccess();
                },
                child: const Text('SIGN IN'),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _editor() => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 52, 24, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONTENT STUDIO',
                style: TextStyle(
                  color: Color(0xFF506C61),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Edit the live site in plain language.',
                style: TextStyle(
                  fontSize: 48,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2.3,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 720,
                child: Text(
                  'Every change autosaves after you pause typing. Visitors receive the new copy on their next page load.',
                  style: TextStyle(
                    color: Color(0xFF62655F),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              for (final section in SiteContentService.sections.entries) ...[
                _section(section.key, section.value),
                const SizedBox(height: 22),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _section(String title, Map<String, String> entries) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Changes save automatically.',
          style: TextStyle(color: Color(0xFF777A74), fontSize: 12),
        ),
        const SizedBox(height: 24),
        for (final entry in entries.entries) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _label(entry.key),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _states[entry.key] ?? '',
                style: TextStyle(
                  color: _states[entry.key] == 'Could not save'
                      ? Colors.red
                      : const Color(0xFF5E756B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TextField(
            controller: _controllers[entry.key],
            minLines: entry.value.length > 90 || entry.value.contains('\n')
                ? 3
                : 1,
            maxLines: 7,
            onChanged: (value) => _queueSave(entry.key, value),
            decoration: const InputDecoration(fillColor: Color(0xFFF7F8F5)),
          ),
          const SizedBox(height: 18),
        ],
      ],
    ),
  );

  String _label(String key) => key
      .split('.')
      .last
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
