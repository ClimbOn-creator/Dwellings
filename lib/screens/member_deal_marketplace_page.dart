import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/deal_room_service.dart';
import '../services/member_deal_marketplace_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/fixed_editorial_background.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/membership_footer.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';
import 'profile_page.dart';

const _ink = Color(0xFF171717);
const _green = Color(0xFF053827);
const _paper = Color(0xFFF4F1EB);
const _surface = Color(0xFFFCFBF8);
const _line = Color(0xFFD6D1C9);
const _muted = Color(0xFF68635D);

enum _StudioView { opportunities, myPitches, dealResponses }

class MemberDealMarketplacePage extends StatefulWidget {
  const MemberDealMarketplacePage({super.key});

  @override
  State<MemberDealMarketplacePage> createState() =>
      _MemberDealMarketplacePageState();
}

class _MemberDealMarketplacePageState extends State<MemberDealMarketplacePage> {
  _StudioView _view = _StudioView.opportunities;
  late Future<List<MemberDealOpportunity>> _opportunities;
  late Future<List<MemberDealPitch>> _myPitches;
  late Future<List<MemberDealPitch>> _responses;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _opportunities = MemberDealMarketplaceService.browse();
    _myPitches = MemberDealMarketplaceService.loadMyPitches();
    _responses = MemberDealMarketplaceService.loadBuyerResponses();
  }

  Future<bool> _ensureSignedIn() async {
    if (BackendService.user != null) return true;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
    if (!mounted || BackendService.user == null) return false;
    setState(_reload);
    return true;
  }

  Future<void> _pitch(MemberDealOpportunity deal) async {
    if (!await _ensureSignedIn() || !mounted) return;
    if (deal.isPreview) {
      _message(
        'This is a privacy-safe preview. Verified member deals become available after the Member Studio database update is applied.',
      );
      return;
    }
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _PitchDialog(deal: deal),
    );
    if (sent == true && mounted) {
      setState(_reload);
      _message('Pitch sent privately to the anonymous buyer.');
    }
  }

  Future<void> _submitDeal() async {
    if (!await _ensureSignedIn() || !mounted) return;
    try {
      final rooms = (await DealRoomService.loadRooms())
          .where((room) => room.isBusiness && room.status != 'archived')
          .toList();
      if (!mounted) return;
      if (rooms.isEmpty) {
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Complete a deal assessment first'),
            content: const Text(
              'Your Deal Screen and Pipeline create the private source record Affinity reviews. Nothing is published automatically.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('NOT NOW'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OPEN PIPELINE'),
              ),
            ],
          ),
        );
        if (open == true && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const DealRoomsPage(initialSide: PlatformSide.business),
            ),
          );
        }
        return;
      }
      final selected = await showModalBottomSheet<DealRoom>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a deal to Affinity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Affinity receives the private assessment. Members see nothing until we create and approve an anonymous summary.',
                  style: TextStyle(color: _muted, height: 1.45),
                ),
                const SizedBox(height: 18),
                for (final room in rooms)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(room.title),
                    subtitle: Text(
                      '${room.city.isEmpty ? 'Location private' : room.city} · ${room.currentStage}',
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.pop(context, room),
                  ),
              ],
            ),
          ),
        ),
      );
      if (selected == null) return;
      await MemberDealMarketplaceService.submitForReview(selected.id);
      if (mounted) {
        _message(
          'Submitted for Affinity review. It remains private until approved.',
        );
      }
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      toolbarHeight: 78,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: FixedEditorialBackground(
      imagePath: 'assets/images/affinity-member-studio.jpg',
      wash: _paper,
      washOpacity: .2,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _hero(),
            Container(
              width: double.infinity,
              color: _paper,
              padding: const EdgeInsets.fromLTRB(22, 38, 22, 84),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _privacyStrip(),
                      const SizedBox(height: 28),
                      _viewSelector(),
                      const SizedBox(height: 26),
                      _currentView(),
                    ],
                  ),
                ),
              ),
            ),
            const MembershipFooter(),
          ],
        ),
      ),
    ),
  );

  Widget _hero() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 460),
      padding: EdgeInsets.fromLTRB(24, compact ? 42 : 80, 24, 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 670),
              padding: const EdgeInsets.all(34),
              color: Colors.white.withValues(alpha: .96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AFFINITY MEMBER STUDIO',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Serious deals.\nThe right people.',
                    style: TextStyle(
                      color: _ink,
                      fontSize: compact ? 40 : 52,
                      height: .98,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'A private opportunity network where Affinity-reviewed deals meet verified acquisition professionals—without exposing the buyer.',
                    style: TextStyle(color: _muted, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton(
                        onPressed: _submitDeal,
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        child: const Text('SUBMIT MY DEAL FOR REVIEW'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfilePage(),
                          ),
                        ),
                        child: const Text('MEMBER PROFILE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _privacyStrip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: const BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, color: Colors.white),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            'PRIVACY BY DESIGN  ·  Members see an Affinity-written summary, score band, region, and support needs. Names, exact addresses, documents, raw assessments, and buyer contact details stay private. Contact is released only when the buyer accepts a pitch.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w600,
              letterSpacing: .25,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _viewSelector() => Wrap(
    spacing: 9,
    runSpacing: 9,
    children: [
      _viewChip(_StudioView.opportunities, 'OPPORTUNITIES'),
      _viewChip(_StudioView.myPitches, 'MY PITCHES'),
      _viewChip(_StudioView.dealResponses, 'MY DEAL RESPONSES'),
    ],
  );

  Widget _viewChip(_StudioView view, String label) => ChoiceChip(
    label: Text(label),
    selected: _view == view,
    selectedColor: _green,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: _view == view ? Colors.white : _ink,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: .7,
    ),
    side: const BorderSide(color: _line),
    onSelected: (_) => setState(() => _view = view),
  );

  Widget _currentView() => switch (_view) {
    _StudioView.opportunities => _opportunityFeed(),
    _StudioView.myPitches => _pitchList(_myPitches, buyerView: false),
    _StudioView.dealResponses => _pitchList(_responses, buyerView: true),
  };

  Widget _opportunityFeed() => FutureBuilder<List<MemberDealOpportunity>>(
    future: _opportunities,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingBlock();
      }
      if (snapshot.hasError) {
        return _AccessState(
          title: 'Member access required',
          message:
              'Sign in with a verified professional profile to browse approved opportunities. Buyer identities remain private.',
          action: 'OPEN MY PROFILE',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage())),
        );
      }
      final deals = snapshot.data ?? [];
      if (deals.isEmpty) {
        return const _AccessState(
          title: 'The review desk is active',
          message:
              'Approved opportunities will appear here after Affinity completes its evaluation and privacy review.',
        );
      }
      return Column(
        children: [
          for (final deal in deals) ...[
            _DealPost(deal: deal, onPitch: () => _pitch(deal)),
            const SizedBox(height: 18),
          ],
        ],
      );
    },
  );

  Widget _pitchList(
    Future<List<MemberDealPitch>> future, {
    required bool buyerView,
  }) => FutureBuilder<List<MemberDealPitch>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingBlock();
      }
      if (BackendService.user == null) {
        return _AccessState(
          title: 'Sign in to see private activity',
          message: buyerView
              ? 'Buyer responses are visible only to the owner of the submitted deal.'
              : 'Your pitches and buyer decisions are visible only to your member account.',
          action: 'SIGN IN',
          onTap: () async {
            if (await _ensureSignedIn() && mounted) setState(_reload);
          },
        );
      }
      if (snapshot.hasError) {
        return _AccessState(
          title: 'Member Studio setup required',
          message: _friendlyError(snapshot.error!),
        );
      }
      final pitches = snapshot.data ?? [];
      if (pitches.isEmpty) {
        return _AccessState(
          title: buyerView ? 'No deal responses yet' : 'No pitches yet',
          message: buyerView
              ? 'When a verified member responds to your published deal, their short pitch and contact details appear here.'
              : 'Review an approved opportunity and send a concise, specific proposal. Your contact details go to the buyer—not the other way around.',
        );
      }
      return Column(
        children: [
          for (final pitch in pitches) ...[
            _PitchCard(
              pitch: pitch,
              buyerView: buyerView,
              onRespond: buyerView
                  ? (status) async {
                      try {
                        await MemberDealMarketplaceService.respondToPitch(
                          pitch.id,
                          status,
                        );
                        if (mounted) setState(_reload);
                      } catch (error) {
                        if (mounted) _message(_friendlyError(error));
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 14),
          ],
        ],
      );
    },
  );
}

class _DealPost extends StatelessWidget {
  const _DealPost({required this.deal, required this.onPitch});
  final MemberDealOpportunity deal;
  final VoidCallback onPitch;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: _green,
              child: Icon(Icons.lock_person_outlined, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANONYMOUS BUYER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: .8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Identity protected · Affinity reviewed',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            _Score(score: deal.affinityScore),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          deal.headline,
          style: const TextStyle(
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '${deal.industry} · ${deal.region} · ${deal.stage}',
          style: const TextStyle(color: _green, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Text(deal.summary, style: const TextStyle(height: 1.6, fontSize: 15)),
        const SizedBox(height: 22),
        Wrap(
          spacing: 20,
          runSpacing: 14,
          children: [
            _Fact(label: 'PRICE BAND', value: deal.purchasePriceBand),
            _Fact(label: 'CAPITAL SOUGHT', value: deal.capitalRequiredBand),
            _Fact(label: 'AFFINITY VIEW', value: deal.scoreLabel),
          ],
        ),
        if (deal.supportNeeded.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final need in deal.supportNeeded)
                Chip(
                  label: Text(need),
                  backgroundColor: const Color(0xFFE7ECE9),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 210,
              child: Text(
                deal.isPreview
                    ? 'PRIVACY-SAFE PREVIEW'
                    : 'ONLY YOUR PITCH IS SHARED',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onPitch,
              style: FilledButton.styleFrom(backgroundColor: _green),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('PITCH THIS DEAL'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PitchDialog extends StatefulWidget {
  const _PitchDialog({required this.deal});
  final MemberDealOpportunity deal;

  @override
  State<_PitchDialog> createState() => _PitchDialogState();
}

class _PitchDialogState extends State<_PitchDialog> {
  final _pitch = TextEditingController();
  final _offer = TextEditingController();
  late final TextEditingController _email;
  bool _confirmed = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: BackendService.user?.email ?? '');
  }

  @override
  void dispose() {
    _pitch.dispose();
    _offer.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_pitch.text.trim().length < 30 ||
        !_email.text.contains('@') ||
        !_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Write a specific pitch, include a valid reply email, and confirm the privacy rule.',
          ),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await MemberDealMarketplaceService.sendPitch(
        opportunityId: widget.deal.id,
        pitch: _pitch.text,
        offerSummary: _offer.text,
        contactEmail: _email.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pitch the anonymous buyer'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deal.headline, style: const TextStyle(color: _muted)),
            const SizedBox(height: 18),
            TextField(
              controller: _pitch,
              maxLength: 420,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your pitch',
                hintText:
                    'Explain what you can offer, why it fits this deal, and the next useful step.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _offer,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Offer summary',
                hintText: 'Example: Indicative loan from 8%, subject to review',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Your reply email'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: const Text(
                'I will not ask Affinity to reveal the buyer. The buyer decides whether to share contact details.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _sending ? null : () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(
        onPressed: _sending ? null : _send,
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: Text(_sending ? 'SENDING…' : 'SEND PRIVATE PITCH'),
      ),
    ],
  );
}

class _PitchCard extends StatelessWidget {
  const _PitchCard({
    required this.pitch,
    required this.buyerView,
    this.onRespond,
  });
  final MemberDealPitch pitch;
  final bool buyerView;
  final ValueChanged<String>? onRespond;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                buyerView
                    ? '${pitch.providerName}${pitch.companyName.isEmpty ? '' : ' · ${pitch.companyName}'}'
                    : pitch.opportunityHeadline,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _StatusPill(pitch.status),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          buyerView ? pitch.providerType : 'Anonymous buyer',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Text(pitch.pitch, style: const TextStyle(height: 1.55)),
        if (pitch.offerSummary.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            pitch.offerSummary,
            style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
          ),
        ],
        if (buyerView && pitch.contactEmail.isNotEmpty) ...[
          const SizedBox(height: 14),
          SelectableText('Reply to ${pitch.contactEmail}'),
        ],
        if (!buyerView && pitch.buyerContactEmail.isNotEmpty) ...[
          const SizedBox(height: 14),
          SelectableText(
            'Buyer accepted · ${pitch.buyerContactEmail}',
            style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
          ),
        ],
        if (buyerView && pitch.status == 'submitted') ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            children: [
              FilledButton(
                onPressed: () => onRespond?.call('accepted'),
                style: FilledButton.styleFrom(backgroundColor: _green),
                child: const Text('ACCEPT & SHARE MY EMAIL'),
              ),
              OutlinedButton(
                onPressed: () => onRespond?.call('declined'),
                child: const Text('DECLINE'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Score extends StatelessWidget {
  const _Score({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    color: const Color(0xFFE7ECE9),
    child: Column(
      children: [
        Text(
          '$score',
          style: const TextStyle(
            color: _green,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'SCORE',
          style: TextStyle(color: _green, fontSize: 8, letterSpacing: .8),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: status == 'accepted'
          ? const Color(0xFFDCECE4)
          : const Color(0xFFEDEAE4),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      status.toUpperCase(),
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 280,
    child: Center(child: CircularProgressIndicator(color: _green)),
  );
}

class _AccessState extends StatelessWidget {
  const _AccessState({
    required this.title,
    required this.message,
    this.action,
    this.onTap,
  });
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(38),
    color: Colors.white,
    child: Column(
      children: [
        const Icon(Icons.lock_outline, color: _green, size: 32),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        if (action != null && onTap != null) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: Text(action!),
          ),
        ],
      ],
    ),
  );
}

String _friendlyError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '');
  if (text.contains('verified Affinity member')) {
    return 'A verified, active professional membership is required to browse and pitch opportunities.';
  }
  if (text.contains('Could not find the function') ||
      text.contains('does not exist')) {
    return 'The Member Studio backend migration still needs to be applied.';
  }
  return text;
}
