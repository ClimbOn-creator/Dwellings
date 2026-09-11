import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/site_content_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import 'auth_page.dart';
import 'acquisition_support_page.dart';

class ContentStudioPage extends StatefulWidget {
  const ContentStudioPage({super.key});

  @override
  State<ContentStudioPage> createState() => _ContentStudioPageState();
}

class _ContentStudioPageState extends State<ContentStudioPage> {
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
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
        : _visualEditor(),
  );

  Widget _visualEditor() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Edit directly on any page',
              style: TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'Open a page, turn on Edit this page, then click text or a picture and choose Edit. Save publishes your changes for everyone. Choose Done editing to use links and navigate.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                SiteContentService.editing.value = true;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AcquisitionSupportPage(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Open visual editor'),
            ),
          ],
        ),
      ),
    ),
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
}
