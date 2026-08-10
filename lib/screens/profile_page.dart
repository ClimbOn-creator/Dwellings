import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/profile_photo.dart';
import 'auth_page.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AccountProfile? _profile;
  DashboardStats? _stats;
  List<MarketplaceProvider> _team = [];
  bool _loading = true;
  bool _saving = false;
  final _name = TextEditingController();
  final _job = TextEditingController();
  final _company = TextEditingController();
  final _bio = TextEditingController();
  String _employment = 'company';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _job.dispose();
    _company.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (BackendService.user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final values = await Future.wait([
        AccountService.loadProfile(),
        AccountService.loadStats(),
        AccountService.loadTeam(),
      ]);
      final profile = values[0] as AccountProfile?;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stats = values[1] as DashboardStats;
        _team = values[2] as List<MarketplaceProvider>;
        _loading = false;
        _name.text = profile?.fullName ?? '';
        _job.text = profile?.jobTitle ?? '';
        _company.text = profile?.companyName ?? '';
        _bio.text = profile?.bio ?? '';
        _employment = profile?.employmentType.isNotEmpty == true
            ? profile!.employmentType
            : 'company';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile: $error')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AccountService.updateProfile(
        fullName: _name.text,
        jobTitle: _job.text,
        companyName: _company.text,
        employmentType: _employment,
        bio: _bio.text,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _photo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';
      await AccountService.uploadProfilePhoto(
        await file.readAsBytes(),
        extension,
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await BackendService.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _ink,
        body: Center(child: CircularProgressIndicator(color: _purple)),
      );
    }
    if (BackendService.user == null) {
      return Scaffold(
        backgroundColor: _ink,
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const AuthPage()),
            ),
            child: const Text('Sign in to open your profile'),
          ),
        ),
      );
    }
    final profile = _profile;
    final stats =
        _stats ??
        const DashboardStats(
          analysisCount: 0,
          teamCount: 0,
          lastAddress: '',
          lastRisk: null,
        );
    return Scaffold(
      backgroundColor: _paper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(profile)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 54),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth >= 720
                              ? (constraints.maxWidth - 36) / 4
                              : (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _StatCard(
                                width: width,
                                value: '${stats.analysisCount}',
                                label: 'Saved analyses',
                              ),
                              _StatCard(
                                width: width,
                                value: '${stats.teamCount}',
                                label: 'Team members',
                              ),
                              _StatCard(
                                width: width,
                                value: stats.lastRisk == null
                                    ? '—'
                                    : '${stats.lastRisk!.round()}/100',
                                label: 'Latest risk score',
                              ),
                              _StatCard(
                                width: width,
                                value: stats.lastAddress.isEmpty
                                    ? 'No draft yet'
                                    : stats.lastAddress,
                                label: 'Latest property',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 42),
                      _profileEditor(profile),
                      const SizedBox(height: 42),
                      const Text(
                        'Your property team',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Professionals you select in the Local Network stay attached to your account.',
                        style: TextStyle(color: Color(0xFF666674)),
                      ),
                      const SizedBox(height: 20),
                      if (_team.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Your team is empty. Open Local Network and add professionals you want to remember.',
                          ),
                        )
                      else
                        ..._team.map(_teamRow),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AccountProfile? profile) => Container(
    color: _ink,
    padding: const EdgeInsets.fromLTRB(28, 22, 28, 54),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const DwellingIqLogo(size: 46),
              ),
              const Spacer(),
              TextButton(
                onPressed: _signOut,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('SIGN OUT'),
              ),
            ],
          ),
          const SizedBox(height: 54),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                children: [
                  ProfilePhoto(
                    size: 112,
                    photoUrl: profile?.photoUrl ?? '',
                    borderRadius: BorderRadius.circular(28),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: IconButton.filled(
                      onPressed: _photo,
                      icon: const Icon(Icons.camera_alt_outlined, size: 17),
                      tooltip: 'Upload profile photo',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName
                          : 'Complete your profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _publicIdentity(profile),
                      style: const TextStyle(
                        color: Color(0xFFBCAEFF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _publicIdentity(AccountProfile? profile) {
    if (profile == null) return 'DwellingsIQ member';
    final parts = [
      profile.jobTitle,
      profile.companyName,
    ].where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? _roleLabel(profile.role) : parts.join(' · ');
  }

  Widget _profileEditor(AccountProfile? profile) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile details',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '${_roleLabel(profile?.role ?? 'user')} account',
          style: const TextStyle(
            color: _purple,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _job,
          decoration: const InputDecoration(
            labelText: 'Job title or specialty',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _company,
          decoration: const InputDecoration(
            labelText: 'Company, firm or practice',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _employment,
          decoration: const InputDecoration(labelText: 'Work arrangement'),
          items: const [
            DropdownMenuItem(
              value: 'company',
              child: Text('Part of a company or firm'),
            ),
            DropdownMenuItem(
              value: 'self_employed',
              child: Text('Self-employed'),
            ),
            DropdownMenuItem(
              value: 'own_practice',
              child: Text('Own practice or company'),
            ),
          ],
          onChanged: (value) =>
              setState(() => _employment = value ?? _employment),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Professional bio or property goals',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _purple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
      ],
    ),
  );

  Widget _teamRow(MarketplaceProvider provider) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        ProfilePhoto(
          size: 58,
          photoUrl: provider.photoUrl,
          exampleIndex: provider.photoIndex,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${provider.jobTitle} · ${provider.company}',
                style: const TextStyle(color: Color(0xFF666674), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.reviewScore.toStringAsFixed(1)} ★ · ${provider.reviewCount} ratings${provider.isExample ? ' · Example profile' : ''}',
                style: const TextStyle(
                  color: _purple,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            await AccountService.removeTeamMember(provider.id);
            await _load();
          },
          icon: const Icon(Icons.close),
          tooltip: 'Remove from team',
        ),
      ],
    ),
  );

  String _roleLabel(String value) => switch (value) {
    'realtor' => 'Realtor',
    'mortgage_broker' => 'Mortgage broker',
    'lawyer' => 'Property lawyer',
    'accountant' => 'Accountant',
    'lender' => 'Bank or lender',
    _ => 'Buyer or investor',
  };
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.value,
    required this.label,
  });
  final double width;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 128),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF777785), fontSize: 10),
        ),
      ],
    ),
  );
}
