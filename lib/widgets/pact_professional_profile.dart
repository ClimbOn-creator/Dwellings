import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/marketplace_service.dart';
import '../services/pact_professional_service.dart';
import 'profile_photo.dart';

const pactProfilePurple = Color(0xFF6255DC);

class PactProfessionalHeader extends StatelessWidget {
  const PactProfessionalHeader({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.coverUrl,
    this.headline = '',
    this.company = '',
    this.location = '',
    this.verified = false,
    this.tags = const [],
    this.actions = const [],
    this.onAvatar,
    this.onCover,
    this.nameWidget,
    this.headlineWidget,
    this.exampleIndex,
  });
  final String name, photoUrl, coverUrl, headline, company, location;
  final int? exampleIndex;
  final bool verified;
  final List<String> tags;
  final List<Widget> actions;
  final VoidCallback? onAvatar, onCover;
  final Widget? nameWidget, headlineWidget;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth >= 700;
      final cover = wide ? 230.0 : 160.0;
      final size = wide ? 138.0 : 106.0;
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: cover + size / 2,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: cover,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFBFB3EF),
                            Color(0xFFF0E7FA),
                            Color(0xFFF5D9EA),
                          ],
                        ),
                      ),
                      child: coverUrl.isEmpty
                          ? null
                          : Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                    ),
                  ),
                  if (onCover != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filledTonal(
                        tooltip: 'Change cover photo',
                        onPressed: onCover,
                        icon: const Icon(Icons.photo_camera_outlined),
                      ),
                    ),
                  Positioned(
                    left: 22,
                    bottom: 0,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ProfilePhoto(
                            size: size,
                            photoUrl: photoUrl,
                            exampleIndex: exampleIndex,
                          ),
                        ),
                        if (onAvatar != null)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filled(
                              tooltip: 'Change profile photo',
                              onPressed: onAvatar,
                              style: IconButton.styleFrom(
                                backgroundColor: pactProfilePurple,
                              ),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nameWidget ??
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: wide ? 32 : 27,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                          color: const Color(0xFF222332),
                        ),
                      ),
                  if (headline.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    headlineWidget ??
                        Text(
                          headline,
                          style: const TextStyle(fontSize: 17, height: 1.4),
                        ),
                  ],
                  if (company.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      company,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF737582),
                      ),
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      location,
                      style: const TextStyle(color: Color(0xFF737582)),
                    ),
                  ],
                  if (verified) ...[
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          color: pactProfilePurple,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Pact profile verified',
                          style: TextStyle(
                            color: pactProfilePurple,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in tags.take(8))
                          Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 12),
                            ),
                            side: BorderSide.none,
                            backgroundColor: const Color(0xFFF0EDFF),
                          ),
                      ],
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(spacing: 10, runSpacing: 10, children: actions),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class PactProfessionalExperience extends StatefulWidget {
  const PactProfessionalExperience({super.key, required this.provider});
  final MarketplaceProvider provider;
  @override
  State<PactProfessionalExperience> createState() =>
      _PactProfessionalExperienceState();
}

class _PactProfessionalExperienceState
    extends State<PactProfessionalExperience> {
  late Future<List<Map<String, dynamic>>> _credentials;
  late Future<bool> _admin;
  bool _reviewing = false;
  String? _reviewError;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _admin = widget.provider.isExample
        ? Future.value(false)
        : PactProfessionalService.canReviewCredentials();
    _credentials = widget.provider.isExample
        ? Future.value([])
        : PactProfessionalService.credentials(widget.provider.id);
  }

  @override
  void didUpdateWidget(covariant PactProfessionalExperience old) {
    super.didUpdateWidget(old);
    if (old.provider.id != widget.provider.id ||
        old.provider.professionalBackground !=
            widget.provider.professionalBackground) {
      _load();
    }
  }

  Future<void> _verify(int index, bool approved) async {
    setState(() {
      _reviewing = true;
      _reviewError = null;
    });
    try {
      await PactProfessionalService.verifyCredential(
        widget.provider,
        index,
        approved,
      );
      if (mounted) setState(_load);
    } catch (_) {
      if (mounted) {
        setState(
          () => _reviewError =
              'Could not update verification. Refresh this profile; another administrator must review your own credentials.',
        );
      }
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  Widget _credentialRow(
    Map<String, dynamic> row,
    int index,
    List<Map<String, dynamic>> records,
    bool failed,
  ) {
    final verified =
        !failed &&
        records.any(
          (c) =>
              c['claim'] is Map &&
              mapEquals(Map<String, dynamic>.from(c['claim'] as Map), row),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _entry(
          '${row['title'] ?? ''}',
          '${row['issuer'] ?? ''} · ${row['jurisdiction'] ?? ''}',
          verified
              ? 'Credential verified by Pact${'${row['expires_on'] ?? ''}'.isEmpty ? '' : ' · expires ${row['expires_on']}'}'
              : 'Self-reported · current verification not confirmed',
        ),
        FutureBuilder<bool>(
          future: _admin,
          builder: (context, snapshot) => snapshot.data != true
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Administrator: only verify after independently checking the issuing body’s register.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: _reviewing
                          ? null
                          : () => _verify(index, !verified),
                      child: Text(
                        verified
                            ? 'Revoke credential verification'
                            : 'Verify credential after independent check',
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _card(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 16),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    ),
  );
  Widget _entry(String title, String subtitle, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Color(0xFF737582))),
        ],
        if (text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(height: 1.5)),
        ],
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final b = ProfessionalBackground(widget.provider.professionalBackground);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card('Specialties & practice', [
          const Text(
            'Experience and service coverage are self-reported.',
            style: TextStyle(color: Color(0xFF737582), fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (b.values('services').isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final key in b.values('services'))
                  Chip(
                    label: Text(pactServices[key] ?? key),
                    side: BorderSide.none,
                    backgroundColor: const Color(0xFFF0EDFF),
                  ),
              ],
            ),
          if (b.values('industries').isNotEmpty)
            Text(
              'Industries · ${b.values('industries').map((v) => pactIndustries[v] ?? v).join(', ')}',
              style: const TextStyle(height: 1.6),
            ),
          if (b.values('transaction_types').isNotEmpty)
            Text(
              'Transactions · ${b.values('transaction_types').map((v) => pactTransactions[v] ?? v).join(', ')}',
              style: const TextStyle(height: 1.6),
            ),
          if (b.values('jurisdictions').isNotEmpty)
            Text(
              'Service jurisdictions · ${b.values('jurisdictions').join(', ')}',
              style: const TextStyle(height: 1.6),
            ),
          if (b.text('deal_min').isNotEmpty && b.text('deal_max').isNotEmpty)
            Text(
              'Typical deal size · ${b.text('currency')} ${b.text('deal_min')}–${b.text('deal_max')}',
              style: const TextStyle(height: 1.6),
            ),
          const SizedBox(height: 8),
          Text(
            pactAvailability[b.text('availability')] ??
                'Availability not confirmed',
            style: const TextStyle(color: pactProfilePurple),
          ),
          if (b.data.isEmpty)
            const Text('This member has not added structured experience yet.'),
        ]),
        _card('Experience', [
          if (b.entries('employment').isEmpty)
            const Text('Work experience has not been added yet.'),
          for (final row in b.entries('employment'))
            _entry(
              '${row['title'] ?? ''}',
              [
                row['organization'],
                '${row['start_year'] ?? ''}${'${row['start_year'] ?? ''}'.isEmpty ? '' : ' – ${'${row['end_year'] ?? ''}'.isEmpty ? 'Present' : row['end_year']}'}',
              ].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
              '${row['description'] ?? ''}',
            ),
        ]),
        _card('Deal experience', [
          const Text(
            'Anonymous examples supplied by the member.',
            style: TextStyle(color: Color(0xFF737582), fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (b.entries('deals').isEmpty)
            const Text(
              'Relevant transaction examples have not been added yet.',
            ),
          for (final row in b.entries('deals'))
            _entry(
              '${row['title'] ?? ''}',
              [
                row['role'],
                row['year'],
                pactIndustries[row['industry']],
                pactTransactions[row['transaction_type']],
              ].whereType<String>().where((v) => v.isNotEmpty).join(' · '),
              '${row['summary'] ?? ''}',
            ),
        ]),
        _card('Credentials', [
          const Text(
            'A verified profile badge does not verify every professional credential.',
            style: TextStyle(color: Color(0xFF737582), fontSize: 12),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _credentials,
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (snapshot.hasError)
                    const Text(
                      'Credential verification status could not load. Please refresh.',
                    ),
                  if (snapshot.connectionState != ConnectionState.done)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_reviewError != null)
                    Text(
                      _reviewError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  for (final (index, row) in b.entries('credentials').indexed)
                    _credentialRow(row, index, records, snapshot.hasError),
                  if (b.entries('credentials').isEmpty)
                    const Text('No professional credentials supplied.'),
                ],
              );
            },
          ),
        ]),
      ],
    );
  }
}
