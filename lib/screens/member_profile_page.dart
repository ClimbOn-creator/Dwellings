import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/platform_side.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/profile_photo.dart';
import '../widgets/app_navigation_menu.dart';
import 'auth_page.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key, required this.provider});

  final MarketplaceProvider provider;

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  bool _added = false;
  bool _changingTeam = false;
  late Future<List<ProviderReview>> _reviews;

  MarketplaceProvider get provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _reviews = MarketplaceService.loadReviews(provider.id);
    _syncTeam();
  }

  Future<void> _syncTeam() async {
    final added = await MarketplaceService.isOnTeam(provider.id);
    if (mounted) setState(() => _added = added);
  }

  Future<void> _toggleTeam() async {
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
      await _syncTeam();
    }
    setState(() => _changingTeam = true);
    try {
      if (_added) {
        await MarketplaceService.removeFromTeam(provider.id);
      } else {
        await MarketplaceService.addToTeam(provider);
      }
      if (mounted) setState(() => _added = !_added);
    } finally {
      if (mounted) setState(() => _changingTeam = false);
    }
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  Future<void> _review() async {
    if (provider.isExample) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Example professionals cannot receive real reviews.'),
        ),
      );
      return;
    }
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    List<ProviderReview> reviews = [];
    try {
      reviews = await _reviews;
    } catch (_) {}
    final mine = reviews
        .where((review) => review.userId == BackendService.user?.id)
        .firstOrNull;
    if (!mounted) return;
    var rating = mine?.rating ?? 5;
    final reviewText = TextEditingController(text: mine?.text ?? '');
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
            '${mine == null ? 'Review' : 'Update review for'} ${provider.name}',
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () => setModalState(() => rating = index + 1),
                      tooltip: '${index + 1} stars',
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: _purple,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewText,
                  onChanged: (_) => setModalState(() {}),
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Your review',
                    hintText:
                        'Describe your experience with this professional.',
                  ),
                ),
                const Text(
                  'Your public name will appear with the review. One review is allowed per professional and can be updated.',
                  style: TextStyle(color: Color(0xFF777785), fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving || reviewText.text.trim().isEmpty
                  ? null
                  : () async {
                      setModalState(() => saving = true);
                      try {
                        await MarketplaceService.saveReview(
                          provider: provider,
                          rating: rating,
                          text: reviewText.text,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        setState(() {
                          _reviews = MarketplaceService.loadReviews(
                            provider.id,
                          );
                        });
                      } catch (error) {
                        setModalState(() => saving = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Could not save review: $error'),
                            ),
                          );
                        }
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Publish review'),
            ),
          ],
        ),
      ),
    );
    reviewText.dispose();
  }

  Future<void> _requestIntroduction() async {
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    final property = TextEditingController();
    final phone = TextEditingController();
    final business = provider.category.side == PlatformSide.business;
    var sending = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Warm introduction to ${provider.name}'),
          content: SizedBox(
            width: 470,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business
                      ? 'Your account name and email are attached automatically. Share only a non-confidential summary of the acquisition help you need.'
                      : 'Your account name and email are attached automatically. Add only the property context this professional needs.',
                  style: const TextStyle(
                    color: Color(0xFF666674),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: property,
                  onChanged: (_) => setModalState(() {}),
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: 'What would you like help with?',
                    hintText: business
                        ? 'Industry, location, deal stage, approximate size and the advice you need. Do not include confidential seller data.'
                        : 'Property, city, budget, timeline and the advice you need.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: sending || property.text.trim().isEmpty
                  ? null
                  : () async {
                      setModalState(() => sending = true);
                      try {
                        await AccountService.requestIntroduction(
                          provider: provider,
                          propertySummary: property.text,
                          phone: phone.text,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.isExample
                                  ? 'Introduction preview complete. Nothing was sent.'
                                  : 'Introduction sent. Track its status from your Profile.',
                            ),
                          ),
                        );
                      } catch (error) {
                        setModalState(() => sending = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not send introduction: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Text(sending ? 'Sending…' : 'Send introduction'),
            ),
          ],
        ),
      ),
    );
    property.dispose();
    phone.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.isExample) _exampleBanner(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final desktop = constraints.maxWidth >= 780;
                        final about = _aboutCard();
                        final contact = _contactCard();
                        return desktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: about),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 2, child: contact),
                                ],
                              )
                            : Column(
                                children: [
                                  about,
                                  const SizedBox(height: 18),
                                  contact,
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 38),
                    _reviewsSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero() => Container(
    color: _ink,
    padding: const EdgeInsets.fromLTRB(26, 22, 26, 58),
    child: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const DwellingIqLogo(size: 46),
                  ),
                  const Spacer(),
                  AppNavigationMenu(side: provider.category.side),
                ],
              ),
              const SizedBox(height: 52),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ProfilePhoto(
                    size: 124,
                    photoUrl: provider.photoUrl,
                    exampleIndex: provider.photoIndex,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            if (provider.verified) _badge('VERIFIED'),
                            if (provider.sponsored) _badge('SPONSORED'),
                            if (provider.isExample) _badge('EXAMPLE'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          provider.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 46,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${provider.jobTitle} · ${provider.company}',
                          style: const TextStyle(
                            color: Color(0xFFBCAEFF),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= 700)
                    FilledButton.icon(
                      onPressed: _changingTeam ? null : _toggleTeam,
                      style: FilledButton.styleFrom(
                        backgroundColor: _added
                            ? const Color(0xFF16825D)
                            : Colors.white,
                        foregroundColor: _added ? Colors.white : _ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                      ),
                      icon: Icon(_added ? Icons.check_circle : Icons.add),
                      label: Text(_added ? 'ADDED!' : 'ADD TO TEAM'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _aboutCard() => _card(
    title: 'About',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.specialty,
          style: const TextStyle(color: Color(0xFF555562), height: 1.6),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _fact(
              Icons.star,
              '${provider.reviewScore.toStringAsFixed(1)} rating',
            ),
            _fact(Icons.history, '${provider.experience} years experience'),
            if (provider.licenseNumber.isNotEmpty)
              _fact(
                Icons.verified_user_outlined,
                '${provider.licenseRegion} licence ${provider.licenseNumber}',
              ),
            _fact(
              provider.acceptingLeads ? Icons.check_circle : Icons.pause_circle,
              provider.acceptingLeads
                  ? 'Accepting new clients'
                  : 'Not accepting new clients',
            ),
          ],
        ),
        if (MediaQuery.sizeOf(context).width < 700) ...[
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _changingTeam ? null : _toggleTeam,
              icon: Icon(_added ? Icons.check_circle : Icons.add),
              label: Text(_added ? 'ADDED!' : 'ADD TO TEAM'),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _contactCard() => _card(
    title: 'Contact & service area',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _contactLine(Icons.business_outlined, provider.company),
        if (provider.locations.isNotEmpty)
          _contactLine(
            Icons.location_on_outlined,
            provider.locations.join(', '),
          ),
        FilledButton.icon(
          onPressed: _requestIntroduction,
          icon: const Icon(Icons.handshake_outlined, size: 18),
          label: const Text('REQUEST A WARM INTRODUCTION'),
        ),
        const SizedBox(height: 10),
        if (provider.phone.isNotEmpty)
          _contactButton(
            Icons.call_outlined,
            provider.phone,
            () => _launch(Uri(scheme: 'tel', path: provider.phone)),
          ),
        if (provider.email.isNotEmpty)
          _contactButton(
            Icons.mail_outline,
            provider.email,
            () => _launch(Uri(scheme: 'mailto', path: provider.email)),
          ),
        if (provider.websiteUrl.isNotEmpty)
          _contactButton(
            Icons.language,
            'Visit website',
            () => _launch(
              Uri.parse(
                provider.websiteUrl.startsWith('http')
                    ? provider.websiteUrl
                    : 'https://${provider.websiteUrl}',
              ),
            ),
          ),
        if (provider.phone.isEmpty &&
            provider.email.isEmpty &&
            provider.websiteUrl.isEmpty)
          const Text(
            'Direct contact details have not been published yet.',
            style: TextStyle(color: Color(0xFF777785), fontSize: 12),
          ),
      ],
    ),
  );

  Widget _reviewsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Member reviews',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton.icon(
            onPressed: _review,
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('RATE & REVIEW'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      FutureBuilder<List<ProviderReview>>(
        future: _reviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _card(
              title: 'Reviews are being enabled',
              child: const Text(
                'The professional profile is ready. Run the included provider reviews migration to activate ratings.',
              ),
            );
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return _card(
              title: 'No member reviews yet',
              child: const Text(
                'Be the first verified member to share an experience.',
              ),
            );
          }
          return Column(children: reviews.map(_reviewCard).toList());
        },
      ),
    ],
  );

  Widget _reviewCard(ProviderReview review) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                review.reviewerName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...List.generate(
              5,
              (index) => Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: _purple,
                size: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(review.text, style: const TextStyle(height: 1.55)),
      ],
    ),
  );

  Widget _card({required String title, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4E4EA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _fact(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EEF9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _purple, size: 15),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _contactLine(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _purple, size: 18),
        const SizedBox(width: 9),
        Expanded(child: SelectableText(text)),
      ],
    ),
  );

  Widget _contactButton(IconData icon, String text, VoidCallback onPressed) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 17),
          label: Align(alignment: Alignment.centerLeft, child: Text(text)),
        ),
      );

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _purple.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _purple.withValues(alpha: .5)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFFD8D0FF),
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _exampleBanner() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEDE9FE),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'EXAMPLE PROFILE · This fictional professional demonstrates the public profile experience. Contact actions and reviews activate for verified members.',
      style: TextStyle(
        color: Color(0xFF4C348F),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
