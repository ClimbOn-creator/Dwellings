import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/backend_service.dart';
import '../services/buyer_resources.dart';
import '../widgets/app_navigation_menu.dart';
import 'auth_page.dart';

class BuyerResourcesPage extends StatelessWidget {
  const BuyerResourcesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F5F7),
    appBar: AppBar(
      title: const Text('Resources'),
      actions: const [AppNavigationMenu(dark: false)],
    ),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(child: SizedBox(width: 1100, child: BuyerResourcesPanel())),
    ),
  );
}

class BuyerResourcesPanel extends StatefulWidget {
  const BuyerResourcesPanel({super.key, this.teamOnly = false});
  final bool teamOnly;
  @override
  State<BuyerResourcesPanel> createState() => _BuyerResourcesPanelState();
}

class _BuyerResourcesPanelState extends State<BuyerResourcesPanel> {
  Set<String> _saved = {};
  String _query = '', _kind = 'All', _region = 'All regions';
  bool _loading = true;
  String? _busy, _error;
  StreamSubscription<dynamic>? _auth;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
    _auth = BackendService.authChanges?.listen((_) => _load());
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _saved = {};
        _error = null;
      });
    }
    try {
      final saved = await BuyerResourceTeam.load();
      if (mounted && generation == _generation) setState(() => _saved = saved);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = 'Your saved resources could not load. Please retry.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggle(BuyerResource resource) async {
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted) return;
      await _load();
      return;
    }
    final wasSaved = _saved.contains(resource.id);
    setState(() => _busy = resource.id);
    try {
      await BuyerResourceTeam.setSaved(resource.id, !wasSaved);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this change. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _open(BuyerResource resource) async {
    try {
      if (!await launchUrl(
        Uri.parse(resource.url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('Unable to open');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText(
              'Open the official resource: ${resource.url}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = buyerResources
        .where(
          (r) =>
              (!widget.teamOnly || _saved.contains(r.id)) &&
              r.matches(_query) &&
              (_kind == 'All' || r.kind == _kind) &&
              (_region == 'All regions' || r.region == _region),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.teamOnly
              ? 'Your public resource team'
              : 'Support for your next acquisition',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          widget.teamOnly
              ? 'Organizations and programs saved to your account. Contact them through their official website.'
              : 'Discover Canadian and B.C. funding, grants and community expertise. Add useful organizations and programs to My Team.',
        ),
        const SizedBox(height: 12),
        if (!widget.teamOnly) ...[
          const Text(
            'Start with the funding directories for a broader search. Grants usually support eligible projects or training; acquisition financing is often a repayable loan. Check current intake and eligibility with each provider.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Sources reviewed September 20, 2026 • Saving a resource does not apply for funding or contact the organization.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5C6074)),
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              labelText: 'Search resources',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in [
                'All',
                'Grants & contributions',
                'Community support',
                'Loans',
                'Funding directory',
              ])
                ChoiceChip(
                  label: Text(kind),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: _region,
            isExpanded: true,
            items: [
              for (final r in ['All regions', 'Canada', 'British Columbia'])
                DropdownMenuItem(
                  value: r,
                  child: Text(r == 'Canada' ? 'Canada-wide programs' : r),
                ),
            ],
            onChanged: (v) => setState(() => _region = v!),
          ),
        ],
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        const SizedBox(height: 16),
        if (visible.isEmpty && !_loading && _error == null)
          Text(
            widget.teamOnly
                ? 'No resources saved yet. Explore Resources to add your first organization.'
                : 'No matching resources. Try another search or category.',
          ),
        for (final resource in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${resource.kind} · ${resource.region}',
                      style: const TextStyle(
                        color: Color(0xFF526DFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      resource.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(resource.summary),
                    const SizedBox(height: 12),
                    Text(
                      resource.eligibility,
                      style: const TextStyle(
                        color: Color(0xFF5C6074),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy != null || _loading || _error != null
                              ? null
                              : () => _toggle(resource),
                          icon: Icon(
                            _saved.contains(resource.id)
                                ? Icons.check
                                : Icons.group_add_outlined,
                          ),
                          label: Text(
                            _busy == resource.id
                                ? 'Saving…'
                                : _saved.contains(resource.id)
                                ? 'Remove from My Team'
                                : BackendService.user == null
                                ? 'Sign in to add to My Team'
                                : 'Add to My Team',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _open(resource),
                          icon: const Icon(Icons.open_in_new, size: 17),
                          label: const Text('Official resource'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
