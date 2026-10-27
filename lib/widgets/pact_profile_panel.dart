import '../services/profile_snapshot_service.dart';
import 'pact_desktop_profile_header.dart';
import 'member_friends_preview.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../services/pact_profile_service.dart';
import 'pact_professional_profile.dart';
import '../screens/pact_professional_editor.dart';

const _green = Color(0xFF6255DC);
const _ink = Color(0xFF222332);

class PactProfilePanel extends StatefulWidget {
  const PactProfilePanel({
    super.key,
    this.initialProfile,
    this.actions = const [],
    this.onChanged,
    this.desktopLayout = false,
    this.load,
  });
  final AccountProfile? initialProfile;
  final List<Widget> actions;
  final VoidCallback? onChanged;
  final bool desktopLayout;
  final Future<PactProfileSnapshot> Function()? load;
  @override
  State<PactProfilePanel> createState() => _PactProfilePanelState();
}

class _PactProfilePanelState extends State<PactProfilePanel>
    with WidgetsBindingObserver {
  int _sectionIndex = 0;
  bool _isMember = false, _settingsOpen = false;
  int _generation = 0;
  StreamSubscription<dynamic>? _auth;
  final _owner = BackendService.user?.id;
  AccountProfile? _profile;
  MarketplaceProvider? _professional;
  List<ProviderReview> _reviews = [];
  bool _uploading = false, _loading = true, _refreshing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    WidgetsBinding.instance.addObserver(this);
    _reload();
    _auth = BackendService.authChanges?.listen((_) {
      if (mounted && BackendService.user?.id != _owner) {
        _generation++;
        setState(() {
          _profile = null;
          _professional = null;
          _reviews = [];
          _isMember = false;
          _loading = false;
          _error = 'Sign in again to load your profile.';
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<void> _reload() async {
    if (_refreshing) return;
    _refreshing = true;
    final id = BackendService.user?.id;
    final generation = ++_generation;
    try {
      final snapshot = await (widget.load ?? ProfileSnapshotService.load)()
          .timeout(const Duration(seconds: 12));
      if (!mounted ||
          generation != _generation ||
          BackendService.user?.id != id)
        return;
      setState(() {
        _profile = snapshot.account ?? _profile;
        _isMember = snapshot.member;
        _professional = snapshot.professional ?? _professional;
        _reviews = snapshot.reviews;
        if ((_sectionIndex == 2 && !_isMember) ||
            (_sectionIndex == 1 && _professional == null))
          _sectionIndex = 0;
        _error = snapshot.warning;
        _loading = false;
      });
    } catch (_) {
      if (mounted &&
          generation == _generation &&
          BackendService.user?.id == id) {
        setState(() {
          _error = 'Could not refresh your profile. Pull down to retry.';
          _loading = false;
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _photo(String slot) async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      if (await PactProfileService.pickImage(slot)) {
        await _reload();
        widget.onChanged?.call();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save this image. Choose a photo your device can open and try again. Your saved image is unchanged unless the upload completed.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _edit() async {
    if (_profile == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PactProfileEditorPage(
          profile: _profile!,
          professional: _professional,
        ),
      ),
    );
    if (saved == true) {
      await _reload();
      widget.onChanged?.call();
    }
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile, professional = _professional;
    final name = p?.fullName.isNotEmpty == true
        ? p!.fullName
        : 'Your Pact profile';
    final description = professional?.personalExperience ?? p?.bio ?? '';
    return LayoutBuilder(
      builder: (context, c) =>
          widget.desktopLayout &&
              c.maxWidth >= 700 &&
              MediaQuery.sizeOf(context).width >= 900
          ? _desktop(p, professional, name, description)
          : _phone(p, professional, name, description),
    );
  }

  Widget _phone(
    AccountProfile? p,
    MarketplaceProvider? professional,
    String name,
    String description,
  ) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const PageStorageKey('pact-profile'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          if (_uploading || (_loading && p == null))
            const LinearProgressIndicator(minHeight: 2),
          PactProfessionalHeader(
            edgeToEdge: true,
            name: name,
            photoUrl: p?.photoUrl ?? '',
            coverUrl: p?.coverUrl ?? '',
            headline: p?.jobTitle ?? '',
            company: p?.companyName ?? '',
            location: professional?.serviceMarkets.join(' · ') ?? '',
            verified: professional?.verified ?? false,
            tags: professional?.specialties ?? const [],
            onAvatar: _uploading ? null : () => _photo('avatar'),
            onCover: _uploading ? null : () => _photo('cover'),
            actions: [
              OutlinedButton.icon(
                onPressed: p == null || _uploading ? null : _edit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit profile'),
              ),
              if (professional != null)
                FilledButton.icon(
                  onPressed: p == null || _uploading ? null : _editExperience,
                  icon: const Icon(Icons.work_outline, size: 18),
                  label: const Text('Edit experience'),
                ),
            ],
          ),
          if (_isMember || professional != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(value: 0, label: Text('Overview')),
                  if (professional != null)
                    const ButtonSegment(value: 1, label: Text('Experience')),
                  if (_isMember)
                    const ButtonSegment(value: 2, label: Text('Friends')),
                ],
                selected: {_sectionIndex},
                onSelectionChanged: (v) =>
                    setState(() => _sectionIndex = v.first),
              ),
            ),
          if (_sectionIndex == 2)
            const Padding(
              padding: EdgeInsets.all(16),
              child: MemberFriendsPreview(),
            ),
          if (_sectionIndex == 0)
            _section('About', [
              Text(
                description.isEmpty
                    ? 'Tell people about yourself and the work you do.'
                    : description,
                style: const TextStyle(height: 1.6, fontSize: 15),
              ),
            ]),
          if (professional != null && _sectionIndex == 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PactProfessionalExperience(provider: professional),
            ),
            _section('Specialties', [
              professional.specialties.isEmpty
                  ? const Text('Add the areas you specialize in.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: professional.specialties
                          .map(
                            (s) => Chip(
                              label: Text(s),
                              backgroundColor: const Color(0xFFF0EDFF),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
            ]),
            _section('Service areas', [
              Text(
                professional.serviceMarkets.isEmpty
                    ? 'Add the markets and regions you serve.'
                    : professional.serviceMarkets.join(' · '),
                style: const TextStyle(height: 1.5),
              ),
            ]),
            _section('Reviews', [
              if (_reviews.isEmpty)
                const Text('Your client reviews will appear here.')
              else
                ..._reviews.take(3).map(_review),
              if (_reviews.length > 3)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Your reviews')),
                        body: ListView(
                          padding: const EdgeInsets.all(24),
                          children: _reviews.map(_review).toList(),
                        ),
                      ),
                    ),
                  ),
                  child: Text('View all ${_reviews.length} reviews'),
                ),
            ]),
          ],
          if (_sectionIndex == 0 && _isMember)
            const Padding(
              padding: EdgeInsets.all(16),
              child: MemberFriendsPreview(),
            ),
          if (_sectionIndex == 0 && widget.actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: _settings(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _settings() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        leading: const Icon(Icons.tune_rounded),
        title: const Text('Account & preferences'),
        trailing: Icon(_settingsOpen ? Icons.expand_less : Icons.expand_more),
        onTap: () => setState(() => _settingsOpen = !_settingsOpen),
      ),
      if (_settingsOpen) ...widget.actions,
    ],
  );

  Widget _desktop(
    AccountProfile? p,
    MarketplaceProvider? professional,
    String name,
    String description,
  ) => RefreshIndicator(
    onRefresh: _reload,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_error != null)
          MaterialBanner(
            content: Text(_error!),
            actions: [
              TextButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        if (_loading || _uploading) const LinearProgressIndicator(minHeight: 2),
        PactDesktopProfileHeader(
          name: name,
          photoUrl: p?.photoUrl ?? '',
          coverUrl: p?.coverUrl ?? '',
          headline: p?.jobTitle ?? '',
          company: p?.companyName ?? '',
          verified: professional?.verified ?? false,
          onAvatar: _uploading ? null : () => _photo('avatar'),
          onCover: _uploading ? null : () => _photo('cover'),
          actions: [
            OutlinedButton.icon(
              onPressed: p == null || _uploading ? null : _edit,
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Edit profile'),
            ),
            if (professional != null)
              FilledButton(
                onPressed: _uploading ? null : _editExperience,
                child: const Text('Edit experience'),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _desktopCard('At a glance', [
                    Text(
                      [
                            p?.jobTitle ?? '',
                            p?.companyName ?? '',
                          ].where((v) => v.isNotEmpty).join(' · ').isEmpty
                          ? 'Your Pact workspace'
                          : [
                              p?.jobTitle ?? '',
                              p?.companyName ?? '',
                            ].where((v) => v.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        height: 1.7,
                        color: Color(0xFF777584),
                      ),
                    ),
                  ]),
                  if (professional != null) ...[
                    const SizedBox(height: 16),
                    _desktopCard('Professional details', [
                      Text(
                        professional.serviceMarkets.isEmpty
                            ? 'Add your service areas'
                            : professional.serviceMarkets.join(' · '),
                        style: const TextStyle(
                          height: 1.6,
                          color: Color(0xFF777584),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final tag in professional.specialties.take(5))
                            Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ]),
                  ],
                  if (widget.actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: _settings(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final item in [
                            (0, 'Overview'),
                            if (professional != null) (1, 'Experience'),
                            if (_isMember) (2, 'Friends'),
                          ])
                            ChoiceChip(
                              label: Text(item.$2),
                              selected: _sectionIndex == item.$1,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _sectionIndex = item.$1),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_sectionIndex == 0) ...[
                    _desktopCard('Introduction', [
                      Text(
                        description.isEmpty
                            ? 'Let your next connection get to know you.'
                            : description,
                        style: const TextStyle(fontSize: 16, height: 1.7),
                      ),
                    ]),
                    if (_isMember)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: MemberFriendsPreview(),
                      ),
                    if (_reviews.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _desktopCard(
                          'Client reviews',
                          _reviews.take(3).map(_review).toList(),
                        ),
                      ),
                  ],
                  if (_sectionIndex == 1 && professional != null)
                    PactProfessionalExperience(provider: professional),
                  if (_sectionIndex == 2) const MemberFriendsPreview(),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _desktopCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE9E6EE)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );

  Future<void> _editExperience() async {
    if (_profile == null || _professional == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PactProfessionalEditor(
          profile: _profile!,
          professional: _professional!,
        ),
      ),
    );
    if (saved == true) {
      await _reload();
      widget.onChanged?.call();
    }
  }

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                color: _ink,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    ),
  );
  Widget _review(ProviderReview review) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                review.reviewerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '★' * review.rating,
              style: const TextStyle(color: Color(0xFFE9AA32), fontSize: 17),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(review.text, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 7),
        Text(
          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  );
}

class PactProfileEditorPage extends StatefulWidget {
  const PactProfileEditorPage({
    super.key,
    required this.profile,
    this.professional,
  });
  final AccountProfile profile;
  final MarketplaceProvider? professional;
  @override
  State<PactProfileEditorPage> createState() => _PactProfileEditorPageState();
}

class _PactProfileEditorPageState extends State<PactProfileEditorPage> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final Map<String, TextEditingController> _fields;
  late final Map<String, String> _original;
  StreamSubscription<dynamic>? _auth;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.profile, professional = widget.professional;
    _fields = {
      'full_name': TextEditingController(text: p.fullName),
      'job_title': TextEditingController(text: p.jobTitle),
      'company_name': TextEditingController(text: p.companyName),
      'bio': TextEditingController(
        text: professional?.personalExperience ?? p.bio,
      ),
      if (professional != null) ...{
        'specialties': TextEditingController(
          text: professional.specialties.join(', '),
        ),
        'service_markets': TextEditingController(
          text: professional.serviceMarkets.join(', '),
        ),
        'phone': TextEditingController(text: professional.phone),
        'website_url': TextEditingController(text: professional.websiteUrl),
      },
    };
    _original = {
      for (final entry in _fields.entries) entry.key: entry.value.text,
    };
    for (final field in _fields.values) {
      field.addListener(_draftChanged);
    }
    _auth = BackendService.authChanges?.listen((_) {
      if (mounted && BackendService.user?.id != widget.profile.id) {
        setState(
          () => _error =
              'Your account changed. Close this editor and sign in again.',
        );
      }
    });
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _experienceEditor() async {
    if (widget.professional == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PactProfessionalEditor(
          profile: widget.profile,
          professional: widget.professional!,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _auth?.cancel();
    _scroll.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _list(String s) => s
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final details = <String, dynamic>{
        for (final f in _fields.entries) f.key: f.value.text.trim(),
      };
      for (final key in ['specialties', 'service_markets']) {
        if (details.containsKey(key)) {
          details[key] = _list(details[key] as String);
        }
      }
      await PactProfileService.save(profile: widget.profile, details: details);
      if (mounted && BackendService.user?.id == widget.profile.id) {
        Navigator.of(context).pop(true);
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message.contains('another device')
              ? 'Your profile changed on another device. Close and reopen this editor to load the latest version.'
              : 'Could not save your profile. Your edits are still here; please retry.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save your profile. Your edits are still here; please retry.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        if (_error != null && _scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text('Edit profile'),
      backgroundColor: Colors.transparent,
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Form(
          key: _form,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Make it yours.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your profile stays up to date across Pact on phone, iPad and web.',
                style: TextStyle(height: 1.5, color: Colors.grey),
              ),
              const SizedBox(height: 28),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _field('full_name', 'Full name', 120, required: true),
              _field('job_title', 'Job title', 120),
              _field('company_name', 'Company or practice', 160),
              _field('bio', 'About you', 4000, lines: 6),
              if (widget.professional != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      _saving ||
                          _fields.entries.any(
                            (e) => e.value.text != _original[e.key],
                          )
                      ? null
                      : _experienceEditor,
                  icon: const Icon(Icons.work_outline),
                  label: const Text('Edit experience & matching details'),
                ),
                const Text(
                  'Save any profile changes before opening the experience editor.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Text(
                  'Professional details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _field(
                  'specialties',
                  'Specialties',
                  1600,
                  hint: 'Business acquisitions, Tax planning',
                ),
                _field(
                  'service_markets',
                  'Service areas',
                  1600,
                  hint: 'Vancouver, British Columbia',
                ),
                _field('phone', 'Public business phone', 60),
                _field(
                  'website_url',
                  'Website',
                  2048,
                  hint: 'https://yourwebsite.com',
                ),
                const Text(
                  'Separate specialties and service areas with commas. These professional details are public.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed:
                    _saving || BackendService.user?.id != widget.profile.id
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.all(17),
                ),
                child: Text(_saving ? 'Saving…' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _field(
    String key,
    String label,
    int max, {
    bool required = false,
    int lines = 1,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey('pact-profile-$key'),
      controller: _fields[key],
      enabled: !_saving,
      maxLength: max,
      minLines: lines,
      maxLines: lines == 1 ? 1 : 12,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        counterText: '',
      ),
      validator: (v) {
        if (required && (v ?? '').trim().isEmpty) return 'Enter your name.';
        if ((v ?? '').length > max) return 'Use up to $max characters.';
        if (['specialties', 'service_markets'].contains(key) &&
            (_list(v ?? '').length > 16 ||
                _list(v ?? '').any((s) => s.length > 100))) {
          return 'Use up to 16 entries, each under 100 characters.';
        }
        if (key == 'website_url' && (v ?? '').trim().isNotEmpty) {
          final u = Uri.tryParse(v!.trim());
          if (u == null ||
              !['http', 'https'].contains(u.scheme) ||
              u.host.isEmpty) {
            return 'Enter a full http or https website URL.';
          }
        }
        return null;
      },
    ),
  );
}
