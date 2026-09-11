import '../widgets/site_text.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/buyer_comparison_profile.dart';
import '../models/platform_side.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/affinity_admin_service.dart';
import '../services/business_sale_bulletin_service.dart';
import '../services/deal_room_service.dart';
import '../services/marketplace_service.dart';
import '../services/member_deal_marketplace_service.dart';
import '../services/member_network_service.dart';
import '../services/member_beta_service.dart';
import '../theme/score_color_scale.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/profile_photo.dart';
import '../widgets/site_copy_text.dart';
import 'auth_page.dart';
import 'bulletin_listing_pages.dart';
import 'deal_rooms_page.dart';
import 'affinity_review_desk_page.dart';
import 'member_profile_page.dart';
import 'professional_onboarding_page.dart';

const _ink = Color(0xFF171717);
const _green = Color(0xFF053827);
const _surface = Color(0xFFFCFBF8);
const _line = Color(0xFFD6D1C9);
const _muted = Color(0xFF68635D);

enum _StudioView {
  opportunities,
  recommendations,
  opportunityDetail,
  saved,
  professionals,
  dealResponses,
  profile,
}

enum _InteractionMode { inbox, chat, deal }

class MemberDealMarketplacePage extends StatefulWidget {
  const MemberDealMarketplacePage({super.key, this.initialChatProvider});

  final MarketplaceProvider? initialChatProvider;

  @override
  State<MemberDealMarketplacePage> createState() =>
      _MemberDealMarketplacePageState();
}

class _MemberDealMarketplacePageState extends State<MemberDealMarketplacePage> {
  _StudioView _view = _StudioView.opportunities;
  late Future<List<MemberDealOpportunity>> _opportunities;
  late Future<List<MemberDealPitch>> _responses;
  late Future<List<MarketplaceProvider>> _professionals;
  late Future<MarketplaceProvider?> _myProfessionalProfile;
  late Future<bool> _creatorAccess;
  late Future<List<MemberConversationSummary>> _conversations;
  Future<List<MemberChatMessage>> _chatMessages = Future.value(const []);
  MemberConversationSummary? _selectedConversation;
  _InteractionMode _interactionMode = _InteractionMode.inbox;
  Timer? _messageRefreshTimer;
  String _professionalQuery = '';
  String _dealQuery = '';
  String _professionalRoleFilter = 'all';
  String _responseFilter = 'all';
  MemberDealOpportunity? _selectedOpportunity;
  bool _interactionPanelOpen = true;
  bool _sendingIntroduction = false;
  final Set<String> _savedOpportunityIds = <String>{};
  final _introduction = TextEditingController();
  final _offer = TextEditingController();
  final _replyEmail = TextEditingController();
  final _professionalSearch = TextEditingController();
  final _dealSearch = TextEditingController();
  final _chatMessage = TextEditingController();
  bool _sendingChat = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadSavedOpportunities();
    _replyEmail.text = BackendService.user?.email ?? '';
    final initialChatProvider = widget.initialChatProvider;
    if (initialChatProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startMemberChat(initialChatProvider);
      });
    }
    _messageRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && BackendService.user != null) {
        setState(() {
          _conversations = MemberNetworkService.loadConversations();
          final conversation = _selectedConversation;
          if (_interactionMode == _InteractionMode.chat &&
              conversation != null) {
            _chatMessages = MemberNetworkService.loadMessages(conversation.id);
          }
        });
      }
    });
  }

  Future<void> _loadSavedOpportunities() async {
    final user = BackendService.user;
    if (user == null) {
      if (mounted) setState(_savedOpportunityIds.clear);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(
      'affinity_saved_opportunities_${user.id}',
    );
    final cloudSaved = await MemberDealMarketplaceService.loadSavedDealIds();
    if (!mounted) return;
    setState(() {
      _savedOpportunityIds
        ..addAll(saved ?? const [])
        ..addAll(cloudSaved);
    });
  }

  Future<void> _toggleSavedOpportunity(String id) async {
    if (!await _ensureSignedIn() || !mounted) return;
    setState(() {
      if (!_savedOpportunityIds.add(id)) _savedOpportunityIds.remove(id);
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'affinity_saved_opportunities_${BackendService.user!.id}',
      _savedOpportunityIds.toList(),
    );
    await MemberDealMarketplaceService.setSaved(
      id,
      _savedOpportunityIds.contains(id),
    );
    if (_savedOpportunityIds.contains(id)) {
      await MemberDealMarketplaceService.recordEngagement(id, 'save');
    }
  }

  @override
  void dispose() {
    _introduction.dispose();
    _offer.dispose();
    _replyEmail.dispose();
    _professionalSearch.dispose();
    _dealSearch.dispose();
    _chatMessage.dispose();
    _messageRefreshTimer?.cancel();
    super.dispose();
  }

  void _reload() {
    _opportunities = MemberDealMarketplaceService.browse();
    _responses = MemberDealMarketplaceService.loadBuyerResponses();
    _professionals = MarketplaceService.loadAffinityMembers();
    _myProfessionalProfile = MarketplaceService.loadMyProfessionalProfile();
    _creatorAccess = AffinityAdminService.isAdmin();
    _conversations = MemberNetworkService.loadConversations();
  }

  Future<bool> _ensureSignedIn() async {
    if (BackendService.user != null) return true;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
    if (!mounted || BackendService.user == null) return false;
    setState(_reload);
    await _loadSavedOpportunities();
    return true;
  }

  Future<void> _pitch(MemberDealOpportunity deal) async {
    if (!await _ensureSignedIn() || !mounted) return;
    if (!deal.canContact) {
      _message(
        'Your professional role is already filled on this deal. You can still contact buyers on other opportunities.',
      );
      return;
    }
    if (deal.isPreview) {
      _message(
        'This is a privacy-safe preview. Verified member deals become available after the Member Studio database update is applied.',
      );
      return;
    }
    if (MediaQuery.sizeOf(context).width >= 900) {
      setState(() {
        _selectedOpportunity = deal;
        _interactionPanelOpen = true;
        _interactionMode = _InteractionMode.deal;
        _introduction.clear();
        _offer.clear();
        if (_replyEmail.text.trim().isEmpty) {
          _replyEmail.text = BackendService.user?.email ?? '';
        }
      });
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
            title: const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.1',
              literal: true,
              'Complete a deal assessment first',
            ),
            content: const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.2',
              literal: true,
              'Your Deal Screen and Pipeline create the private source record Affinity reviews. Nothing is published automatically.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.3',
                  literal: true,
                  'NOT NOW',
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.4',
                  literal: true,
                  'OPEN PIPELINE',
                ),
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
                const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.5',
                  literal: true,
                  'Send a deal to Affinity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.6',
                  literal: true,
                  'Affinity receives the private assessment. Members see nothing until we create and approve an anonymous summary.',
                  style: TextStyle(color: _muted, height: 1.45),
                ),
                const SizedBox(height: 18),
                for (final room in rooms)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.m1',
                      literal: false,
                      room.title,
                    ),
                    subtitle: SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.m2',
                      literal: false,
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
      final details =
          selected.propertySnapshot['deal_details'] as String? ?? '';
      if (details.trim().length < 40) {
        if (!mounted) return;
        final edit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.7',
              literal: true,
              'Add a short deal description',
            ),
            content: const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.8',
              literal: true,
              'Every submitted deal needs a short paragraph explaining the business, what interests you, and what you are trying to accomplish. This remains private until Affinity creates the anonymous member brief.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.9',
                  literal: true,
                  'NOT NOW',
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.10',
                  literal: true,
                  'EDIT DEAL',
                ),
              ),
            ],
          ),
        );
        if (edit == true && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DealRoomPage(room: selected),
            ),
          );
        }
        return;
      }
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

  Future<void> _openMatchSettings() async {
    if (!await _ensureSignedIn() || !mounted) return;
    try {
      final current = await MemberBetaService.loadPreferences();
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _MatchSettingsDialog(current: current),
      );
      if (saved == true && mounted) setState(_reload);
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: SiteText(
        contentKey: 'copy.member_deal_marketplace_page.m3',
        literal: false,
        text,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F3EF),
    appBar: AppBar(
      toolbarHeight: 72,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      title: Row(
        children: [
          const HomeBrandButton(size: 52, dark: false),
          if (MediaQuery.sizeOf(context).width >= 620) ...[
            const SizedBox(width: 14),
            const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.11',
              literal: true,
              'MEMBER STUDIO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          onPressed: _submitDeal,
          tooltip: 'Submit a deal to Affinity',
          icon: const Icon(Icons.add_business_outlined),
        ),
        FutureBuilder<bool>(
          future: AffinityAdminService.isAdmin(),
          builder: (context, snapshot) => snapshot.data == true
              ? IconButton(
                  tooltip: 'Affinity review desk',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AffinityReviewDeskPage(),
                    ),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          onPressed: _reloadAndRebuild,
          tooltip: 'Refresh studio',
          icon: const Icon(Icons.refresh_rounded),
        ),
        const AppNavigationMenu(side: PlatformSide.business, dark: false),
        const SizedBox(width: 10),
      ],
    ),
    body: _workspace(),
  );

  void _reloadAndRebuild() => setState(_reload);

  void _selectView(_StudioView view) => setState(() {
    _view = view;
    if (view == _StudioView.dealResponses) _interactionPanelOpen = false;
  });

  Widget _workspace() => Container(
    width: double.infinity,
    color: const Color(0xFFF1F3EF),
    padding: const EdgeInsets.all(14),
    child: LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 900;
        if (!desktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _viewSelector(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _currentView(),
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 76, child: _dashboardNavigation()),
            const SizedBox(width: 14),
            Expanded(
              child: Material(
                color: const Color(0xFFF7F5F0),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 26, 28, 60),
                  child: _currentView(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _interactionPanelOpen ? 350 : 58,
              child: _interactionPanelOpen
                  ? _memberInteractionPanel()
                  : _collapsedInteractionPanel(),
            ),
          ],
        );
      },
    ),
  );

  Widget _dashboardNavigation() => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      child: ListView(
        children: [
          _dashboardNavItem(
            _StudioView.opportunities,
            Icons.work_outline_rounded,
            'Opportunities',
          ),
          _dashboardNavItem(
            _StudioView.recommendations,
            Icons.auto_awesome_outlined,
            'Recommendations',
          ),
          _dashboardNavItem(
            _StudioView.saved,
            Icons.bookmark_border_rounded,
            'Saved',
          ),
          _dashboardNavItem(
            _StudioView.professionals,
            Icons.people_outline_rounded,
            'Professionals',
          ),
          _dashboardNavItem(
            _StudioView.dealResponses,
            Icons.inbox_outlined,
            'Buyer inbox',
          ),
          _dashboardNavItem(
            _StudioView.profile,
            Icons.person_outline_rounded,
            'My profile',
          ),
        ],
      ),
    ),
  );

  Widget _dashboardNavItem(_StudioView view, IconData icon, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => _selectView(view),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _view == view ? _green : const Color(0xFFF4F1EB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 20,
                color: _view == view ? Colors.white : _green,
              ),
            ),
          ),
        ),
      );

  Widget _collapsedInteractionPanel() => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: Column(
      children: [
        const SizedBox(height: 12),
        IconButton(
          onPressed: () => setState(() => _interactionPanelOpen = true),
          tooltip: 'Open interaction panel',
          icon: const Icon(Icons.forum_outlined, color: _green),
        ),
        const SizedBox(height: 8),
        const RotatedBox(
          quarterTurns: 1,
          child: SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m4',
            literal: true,
            'MESSAGES',
            style: TextStyle(
              color: _green,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _memberInteractionPanel() => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 13),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE7EEE9),
                child: Icon(Icons.forum_outlined, color: _green, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.m5',
                  literal: false,
                  switch (_interactionMode) {
                    _InteractionMode.inbox => 'Messages',
                    _InteractionMode.chat =>
                      _selectedConversation?.name ?? 'Conversation',
                    _InteractionMode.deal => 'Anonymous buyer',
                  },
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _interactionMode = _InteractionMode.inbox;
                  _selectedConversation = null;
                }),
                tooltip: 'Member messages',
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: _interactionMode == _InteractionMode.inbox
                      ? _green
                      : _muted,
                ),
              ),
              if (_selectedOpportunity != null)
                IconButton(
                  onPressed: () =>
                      setState(() => _interactionMode = _InteractionMode.deal),
                  tooltip: 'Deal introduction',
                  icon: Icon(
                    Icons.business_center_outlined,
                    color: _interactionMode == _InteractionMode.deal
                        ? _green
                        : _muted,
                  ),
                ),
              IconButton(
                onPressed: () => setState(() => _interactionPanelOpen = false),
                tooltip: 'Collapse',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _line),
        Expanded(
          child: switch (_interactionMode) {
            _InteractionMode.inbox => _conversationInbox(),
            _InteractionMode.chat => _conversationView(),
            _InteractionMode.deal =>
              _selectedOpportunity == null
                  ? _dealIntroductionEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: _introductionComposer(_selectedOpportunity!),
                    ),
          },
        ),
      ],
    ),
  );

  Widget _dealIntroductionEmptyState() => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.business_center_outlined, size: 36, color: _green),
        SizedBox(height: 16),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m6',
          literal: true,
          'Choose an opportunity',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 9),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m7',
          literal: true,
          'Open an Affinity-reviewed deal and make one concise, relevant introduction. The buyer remains anonymous unless they choose to connect.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );

  Widget _conversationInbox() => BackendService.user == null
      ? const Center(
          child: SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m8',
            literal: true,
            'Message board',
            style: TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        )
      : FutureBuilder<List<MemberConversationSummary>>(
          future: _conversations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            }
            if (snapshot.hasError) {
              return _AccessState(
                title: 'Messages are unavailable',
                message: _friendlyError(snapshot.error!),
                action: 'TRY AGAIN',
                onTap: () => setState(
                  () =>
                      _conversations = MemberNetworkService.loadConversations(),
                ),
              );
            }
            final conversations = snapshot.data ?? const [];
            if (conversations.isEmpty) {
              return const _AccessState(
                title: 'Start a conversation',
                message:
                    'Open a verified member profile or choose a professional from a deal team, then select Message.',
              );
            }
            return RefreshIndicator(
              color: _green,
              onRefresh: () async {
                final future = MemberNetworkService.loadConversations();
                setState(() => _conversations = future);
                await future;
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: _line),
                itemBuilder: (context, index) =>
                    _conversationTile(conversations[index]),
              ),
            );
          },
        );

  Widget _conversationTile(MemberConversationSummary conversation) => InkWell(
    onTap: () => _openConversation(conversation),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfilePhoto(
                size: 48,
                photoUrl: conversation.photoUrl,
                exampleIndex: conversation.photoIndex,
              ),
              if (conversation.unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF168A52),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.m9',
                        literal: false,
                        conversation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.m10',
                      literal: false,
                      _relativeMessageTime(conversation.lastMessageAt),
                      style: TextStyle(
                        color: conversation.unreadCount > 0 ? _green : _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.m11',
                        literal: false,
                        conversation.lastMessage.isEmpty
                            ? 'New conversation'
                            : conversation.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: conversation.unreadCount > 0 ? _ink : _muted,
                          fontSize: 11,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (conversation.unreadCount > 0) ...[
                      const SizedBox(width: 7),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SiteText(
                          contentKey: 'copy.member_deal_marketplace_page.m12',
                          literal: false,
                          '${conversation.unreadCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (conversation.opportunityHeadline.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m13',
                    literal: false,
                    conversation.opportunityHeadline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _green,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _openConversation(MemberConversationSummary conversation) async {
    setState(() {
      _selectedConversation = conversation;
      _interactionMode = _InteractionMode.chat;
      _interactionPanelOpen = true;
      _chatMessages = MemberNetworkService.loadMessages(conversation.id);
    });
    await MemberNetworkService.markRead(conversation.id);
    if (mounted) {
      setState(() => _conversations = MemberNetworkService.loadConversations());
    }
  }

  Widget _conversationView() {
    final conversation = _selectedConversation;
    if (conversation == null) return _conversationInbox();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
          color: const Color(0xFFF7F5F0),
          child: Row(
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => _interactionMode = _InteractionMode.inbox),
                icon: const Icon(Icons.arrow_back_rounded, size: 19),
              ),
              ProfilePhoto(
                size: 38,
                photoUrl: conversation.photoUrl,
                exampleIndex: conversation.photoIndex,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.m14',
                      literal: false,
                      conversation.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.m15',
                      literal: false,
                      conversation.jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (conversation.opportunityHeadline.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE7EEE9),
            child: SiteText(
              templateValues: {'value1': '${conversation.opportunityHeadline}'},
              contentKey: 'copy.member_deal_marketplace_page.m16',
              literal: false,
              "DEAL · {{value1}}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _green,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<MemberChatMessage>>(
            future: _chatMessages,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _green),
                );
              }
              final messages = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) =>
                    _messageBubble(messages[index]),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatMessage,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    decoration: const InputDecoration(
                      hint: SiteText(
                        'Message…',
                        contentKey: 'copy.member_deal_marketplace_page.field1',
                        literal: true,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton.filled(
                  onPressed: _sendingChat ? null : _sendChatMessage,
                  style: IconButton.styleFrom(backgroundColor: _green),
                  icon: _sendingChat
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageBubble(MemberChatMessage message) => Align(
    alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 250),
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: message.isMine ? _green : const Color(0xFFF1F3EF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m17',
            literal: false,
            message.body,
            style: TextStyle(
              color: message.isMine ? Colors.white : _ink,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m18',
            literal: false,
            _relativeMessageTime(message.createdAt),
            style: TextStyle(
              color: message.isMine ? Colors.white70 : _muted,
              fontSize: 8,
            ),
          ),
          if (message.isMine) ...[
            const SizedBox(height: 2),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m19',
              literal: false,
              message.readAt == null
                  ? 'Sent'
                  : 'Read ${DateFormat.jm().format(message.readAt!.toLocal())}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _sendChatMessage() async {
    final conversation = _selectedConversation;
    final body = _chatMessage.text.trim();
    if (conversation == null || body.isEmpty) return;
    if (conversation.isPreview) {
      _message('Sign in with a verified member profile to send messages.');
      return;
    }
    setState(() => _sendingChat = true);
    try {
      await MemberNetworkService.sendMessage(conversation.id, body);
      _chatMessage.clear();
      if (mounted) {
        setState(() {
          _chatMessages = MemberNetworkService.loadMessages(conversation.id);
          _conversations = MemberNetworkService.loadConversations();
        });
      }
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _sendingChat = false);
    }
  }

  Future<void> _startMemberChat(
    MarketplaceProvider provider, {
    MemberDealOpportunity? deal,
  }) async {
    if (provider.isExample) {
      _message('Example profiles cannot receive live messages.');
      return;
    }
    if (!await _ensureSignedIn() || !mounted) return;
    try {
      final myProfile = await _myProfessionalProfile;
      if (myProfile?.id == provider.id) {
        _message('This is your profile. Choose another member to message.');
        return;
      }
      final conversationId = await MemberNetworkService.startConversation(
        providerId: provider.id,
        opportunityId: deal?.isPreview == true ? null : deal?.id,
      );
      final conversations = await MemberNetworkService.loadConversations();
      final conversation = conversations
          .where((item) => item.id == conversationId)
          .firstOrNull;
      if (!mounted || conversation == null) return;
      setState(() {
        _conversations = Future.value(conversations);
        _interactionPanelOpen = true;
      });
      await _openConversation(conversation);
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    }
  }

  Future<MarketplaceProvider?> _providerForTeamMember(
    MemberDealTeamMember member,
  ) async {
    final providers = await _professionals;
    return providers
        .where(
          (provider) =>
              provider.id == member.providerId || provider.name == member.name,
        )
        .firstOrNull;
  }

  Future<void> _openTeamMemberProfile(
    MemberDealTeamMember member,
    MemberDealOpportunity deal,
  ) async {
    final provider = await _providerForTeamMember(member);
    if (!mounted) return;
    if (provider == null) {
      _message('That member profile is not available yet.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfilePage(
          provider: provider,
          onMessage: () => _startMemberChat(provider, deal: deal),
          onRefer: () => _showReferralDialog(deal, preselected: provider),
        ),
      ),
    );
  }

  Future<void> _showReferralDialog(
    MemberDealOpportunity deal, {
    MarketplaceProvider? preselected,
  }) async {
    if (!await _ensureSignedIn() || !mounted) return;
    final providers = (await _professionals)
        .where((provider) => !provider.isExample)
        .toList();
    if (!mounted) return;
    final referral =
        await showDialog<({MarketplaceProvider provider, String note})>(
          context: context,
          builder: (_) => _ReferralDialog(
            deal: deal,
            providers: providers,
            preselected: preselected?.isExample == false ? preselected : null,
          ),
        );
    if (referral == null || !mounted) return;
    if (deal.isPreview) {
      _message('Referrals become available on live Affinity-reviewed deals.');
      return;
    }
    try {
      await MemberNetworkService.referToDeal(
        opportunityId: deal.id,
        providerId: referral.provider.id,
        note: referral.note,
      );
      if (mounted) {
        _message('${referral.provider.name} was referred to this deal.');
      }
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    }
  }

  String _relativeMessageTime(DateTime value) {
    final local = value.toLocal();
    final difference = DateTime.now().difference(local);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${local.month}/${local.day}/${local.year.toString().substring(2)}';
  }

  Widget _introductionComposer(MemberDealOpportunity deal) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.12',
              literal: true,
              'ANONYMOUS OPPORTUNITY',
              style: TextStyle(
                color: _green,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m20',
              literal: false,
              deal.headline,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m21',
              literal: false,
              '${deal.industry} · ${deal.region}',
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _toggleSavedOpportunity(deal.id),
          icon: Icon(
            _savedOpportunityIds.contains(deal.id)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: 17,
          ),
          label: SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m22',
            literal: false,
            _savedOpportunityIds.contains(deal.id)
                ? 'SAVED TO WATCHLIST'
                : 'SAVE TO WATCHLIST',
          ),
        ),
      ),
      const SizedBox(height: 18),
      const SiteText(
        contentKey: 'copy.member_deal_marketplace_page.13',
        literal: true,
        'Your introduction',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      const SiteText(
        contentKey: 'copy.member_deal_marketplace_page.14',
        literal: true,
        'Explain specifically how you can help this deal.',
        style: TextStyle(color: _muted, fontSize: 11),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _introduction,
        minLines: 5,
        maxLines: 7,
        maxLength: 420,
        decoration: const InputDecoration(
          hint: SiteText(
            'We can support this acquisition by…',
            contentKey: 'copy.member_deal_marketplace_page.field2',
            literal: true,
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _offer,
        maxLength: 120,
        decoration: const InputDecoration(
          label: SiteText(
            'Offer summary',
            contentKey: 'copy.member_deal_marketplace_page.field3',
            literal: true,
          ),
          hint: SiteText(
            'Example: Acquisition loan from 8%',
            contentKey: 'copy.member_deal_marketplace_page.field4',
            literal: true,
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _replyEmail,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          label: SiteText(
            'Contact email',
            contentKey: 'copy.member_deal_marketplace_page.field5',
            literal: true,
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _sendingIntroduction
              ? null
              : () => _sendIntroduction(deal),
          icon: _sendingIntroduction
              ? const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined, size: 17),
          label: SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m23',
            literal: false,
            _sendingIntroduction ? 'SENDING…' : 'SEND PRIVATE INTRODUCTION',
          ),
        ),
      ),
      const SizedBox(height: 12),
      const SiteText(
        contentKey: 'copy.member_deal_marketplace_page.15',
        literal: true,
        'Your contact information is shown to the buyer. Their identity and contact information remain private until they accept.',
        style: TextStyle(color: _muted, fontSize: 10, height: 1.45),
      ),
    ],
  );

  Future<void> _sendIntroduction(MemberDealOpportunity deal) async {
    final pitch = _introduction.text.trim();
    final email = _replyEmail.text.trim();
    if (pitch.length < 30 || pitch.length > 420 || !email.contains('@')) {
      _message(
        'Add a 30–420 character introduction and a valid contact email.',
      );
      return;
    }
    setState(() => _sendingIntroduction = true);
    try {
      await MemberDealMarketplaceService.sendPitch(
        opportunityId: deal.id,
        pitch: pitch,
        offerSummary: _offer.text,
        contactEmail: email,
      );
      await MemberDealMarketplaceService.recordEngagement(deal.id, 'pitch');
      _introduction.clear();
      _offer.clear();
      _reload();
      if (mounted) {
        setState(() => _selectedOpportunity = null);
        _message('Your private introduction was sent to the anonymous buyer.');
      }
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _sendingIntroduction = false);
    }
  }

  Widget _viewSelector() => Wrap(
    spacing: 9,
    runSpacing: 9,
    children: [
      _viewChip(_StudioView.opportunities, 'OPPORTUNITIES'),
      _viewChip(_StudioView.recommendations, 'RECOMMENDATIONS'),
      _viewChip(_StudioView.saved, 'SAVED'),
      _viewChip(_StudioView.professionals, 'PROFESSIONALS'),
      _viewChip(_StudioView.dealResponses, 'MY DEAL RESPONSES'),
      _viewChip(_StudioView.profile, 'PROFILE'),
    ],
  );

  Widget _viewChip(_StudioView view, String label) => ChoiceChip(
    label: SiteText(
      contentKey: 'copy.member_deal_marketplace_page.m24',
      literal: false,
      label,
    ),
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
    onSelected: (_) => _selectView(view),
  );

  Widget _currentView() {
    const privateViews = <_StudioView>{
      _StudioView.recommendations,
      _StudioView.saved,
      _StudioView.dealResponses,
      _StudioView.profile,
    };
    if (privateViews.contains(_view) && BackendService.user == null) {
      return _AccessState(
        title: 'Your private member workspace',
        message:
            'Sign in to open this area. Recommendations, saved deals, buyer responses, and professional-profile information are tied only to your Affinity account.',
        action: 'SIGN IN',
        onTap: () async {
          if (await _ensureSignedIn() && mounted) setState(_reload);
        },
      );
    }
    return switch (_view) {
      _StudioView.opportunities => _opportunityFeed(),
      _StudioView.recommendations => _matchedOpportunities(),
      _StudioView.opportunityDetail => _expandedOpportunity(),
      _StudioView.saved => _savedOpportunities(),
      _StudioView.professionals => _professionalDirectory(),
      _StudioView.dealResponses => _pitchList(_responses, buyerView: true),
      _StudioView.profile => _professionalProfileWorkspace(),
    };
  }

  Widget _studioHeading(String eyebrow, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m25',
              literal: false,
              eyebrow,
              style: const TextStyle(
                color: _green,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m26',
              literal: false,
              title,
              style: const TextStyle(
                fontSize: 32,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.3,
              ),
            ),
            const SizedBox(height: 9),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m27',
              literal: false,
              description,
              style: const TextStyle(color: _muted, height: 1.45),
            ),
          ],
        ),
      );

  void _openOpportunity(MemberDealOpportunity deal) {
    MemberDealMarketplaceService.recordEngagement(deal.id, 'open');
    setState(() {
      _selectedOpportunity = deal;
      _view = _StudioView.opportunityDetail;
    });
  }

  Future<void> _repostDeal(MemberDealOpportunity deal) async {
    try {
      await MemberDealMarketplaceService.repost(deal.id);
      if (!mounted) return;
      setState(_reload);
      _message('Deal reposted and moved to the top of the marketplace.');
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    }
  }

  Widget _expandedOpportunity() {
    final deal = _selectedOpportunity;
    if (deal == null) {
      return _AccessState(
        title: 'Choose an opportunity',
        message:
            'Open a deal from Opportunities, Recommendations, or Saved to see its complete privacy-safe brief.',
        action: 'BROWSE OPPORTUNITIES',
        onTap: () => _selectView(_StudioView.opportunities),
      );
    }
    String detail(String key, String fallback) {
      final value = deal.publicDetails[key]?.trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    final criteria = <({String label, String value, IconData icon})>[
      (
        label: 'BUYER OBJECTIVE',
        value: detail(
          'buyer_objective',
          'The buyer is evaluating an acquisition that fits the profile summarized below.',
        ),
        icon: Icons.flag_outlined,
      ),
      (
        label: 'TARGET BUSINESS PROFILE',
        value: detail('target_business', deal.summary),
        icon: Icons.business_center_outlined,
      ),
      (
        label: 'OPERATING PROFILE',
        value: detail(
          'operating_profile',
          'Operating and management expectations will be confirmed during diligence.',
        ),
        icon: Icons.settings_suggest_outlined,
      ),
      (
        label: 'FINANCING PLAN',
        value: detail(
          'financing_plan',
          '${deal.capitalRequiredBand} of capital is currently anticipated.',
        ),
        icon: Icons.account_balance_outlined,
      ),
      (
        label: 'TIMELINE',
        value: detail(
          'timeline',
          'Timing remains flexible at the ${deal.stage} stage.',
        ),
        icon: Icons.calendar_month_outlined,
      ),
      (
        label: 'TRANSACTION PREFERENCES',
        value: detail(
          'transaction_preferences',
          'Final structure remains subject to diligence and professional advice.',
        ),
        icon: Icons.handshake_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => _selectView(_StudioView.opportunities),
          icon: const Icon(Icons.arrow_back_rounded, size: 17),
          label: const SiteText(
            contentKey: 'copy.member_deal_marketplace_page.16',
            literal: true,
            'ALL OPPORTUNITIES',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 27,
              backgroundColor: _green,
              child: Icon(Icons.business_center_outlined, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.17',
                    literal: true,
                    'ANONYMOUS ACQUISITION BRIEF · AFFINITY REVIEWED',
                    style: TextStyle(
                      color: _green,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m28',
                    literal: false,
                    deal.headline,
                    style: const TextStyle(
                      fontSize: 36,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m29',
                    literal: false,
                    '${deal.industry} · ${deal.region} · ${deal.stage}',
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _Score(
              score: deal.matchScore ?? deal.affinityScore,
              label: deal.matchScore == null ? 'DEAL' : 'MATCH',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: _green, size: 19),
                  SizedBox(width: 9),
                  SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m30',
                    literal: true,
                    'IDENTITY-SAFE LISTING',
                    style: TextStyle(
                      color: _green,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SiteText(
                contentKey: 'copy.member_deal_marketplace_page.18',
                literal: true,
                'The title is deliberately broad',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              const SiteText(
                contentKey: 'copy.member_deal_marketplace_page.19',
                literal: true,
                'Affinity removes the company name, exact address, buyer identity, contact details, and other identifying information before members can view this brief.',
                style: TextStyle(color: _muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.20',
          literal: true,
          'Opportunity overview',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteText(
                contentKey: 'copy.member_deal_marketplace_page.21',
                literal: true,
                'BUYER-SUBMITTED DESCRIPTION',
                style: TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              SiteText(
                contentKey: 'copy.member_deal_marketplace_page.m31',
                literal: false,
                deal.summary,
                style: const TextStyle(fontSize: 17, height: 1.65),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricTile(deal.purchasePriceBand, 'PURCHASE PRICE'),
            _metricTile(deal.capitalRequiredBand, 'CAPITAL SOUGHT'),
            _metricTile(
              detail('revenue_profile', 'Not disclosed'),
              'REVENUE PROFILE',
            ),
            _metricTile(
              detail('earnings_profile', 'Not disclosed'),
              'EARNINGS PROFILE',
            ),
            _metricTile(deal.stage, 'CURRENT STAGE'),
          ],
        ),
        const SizedBox(height: 30),
        const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.22',
          literal: true,
          'Acquisition criteria',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 7),
        const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.23',
          literal: true,
          'A reviewer-approved breakdown of the buyer’s submitted requirements.',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 760
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final item in criteria)
                  _BriefSection(
                    width: width,
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _BriefSection(
          width: double.infinity,
          icon: Icons.fact_check_outlined,
          label: 'DILIGENCE PRIORITIES',
          value: detail(
            'diligence_priorities',
            'Financial, legal, commercial, and operational priorities will be refined with the selected deal team.',
          ),
        ),
        const SizedBox(height: 30),
        const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.24',
          literal: true,
          'Professional mandate',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 12),
        _studioPanel(
          Icons.groups_2_outlined,
          'Support requested by the buyer',
          deal.supportNeeded.isEmpty
              ? 'Affinity has not assigned professional requirements yet.'
              : deal.supportNeeded.join(' · '),
        ),
        const SizedBox(height: 18),
        _DealTeamStrip(
          members: deal.teamMembers,
          onOpen: (member) => _openTeamMemberProfile(member, deal),
          onMessage: (member) async {
            final provider = await _providerForTeamMember(member);
            if (provider != null) await _startMemberChat(provider, deal: deal);
          },
          onRefer: (member) async {
            final provider = await _providerForTeamMember(member);
            if (provider != null) {
              await _showReferralDialog(deal, preselected: provider);
            }
          },
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => _toggleSavedOpportunity(deal.id),
              icon: Icon(
                _savedOpportunityIds.contains(deal.id)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              label: SiteText(
                contentKey: 'copy.member_deal_marketplace_page.m32',
                literal: false,
                _savedOpportunityIds.contains(deal.id)
                    ? 'SAVED'
                    : 'SAVE OPPORTUNITY',
              ),
            ),
            FilledButton.icon(
              onPressed: deal.canContact
                  ? () {
                      setState(() => _interactionPanelOpen = true);
                      _pitch(deal);
                    }
                  : null,
              icon: Icon(
                deal.canContact
                    ? Icons.forum_outlined
                    : Icons.person_off_outlined,
                size: 17,
              ),
              label: SiteText(
                contentKey: 'copy.member_deal_marketplace_page.m33',
                literal: false,
                deal.canContact
                    ? 'INTRODUCE YOUR SERVICES'
                    : 'YOUR ROLE IS FILLED',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _matchedOpportunities() => FutureBuilder<List<MemberDealOpportunity>>(
    future: _opportunities,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const _LoadingBlock();
      final deals = MemberDealMarketplaceService.rankRecommendations(
        snapshot.data!,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _studioHeading(
            'PERSONALIZED DISCOVERY',
            'Recommended for you',
            'Affinity ranks reviewed opportunities against your services, regions, and deal-size preferences.',
          ),
          FutureBuilder<bool>(
            future: _creatorAccess,
            builder: (context, creator) => creator.data == true
                ? Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5EEE9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.25',
                      literal: true,
                      'CREATOR FILTER · VICTORIA ONLY',
                      style: TextStyle(
                        color: _green,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Row(
            children: [
              Expanded(
                child: _metricTile('${deals.length}', 'RECOMMENDATIONS'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricTile(
                  deals.isEmpty
                      ? '—'
                      : '${deals.first.matchScore ?? deals.first.affinityScore}%',
                  'BEST FIT',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final deal in deals) ...[
            _DealPost(
              deal: deal,
              onOpen: () => _openOpportunity(deal),
              onPitch: () => _pitch(deal),
              onRefer: () => _showReferralDialog(deal),
              onRepost: deal.canRepost ? () => _repostDeal(deal) : null,
              onTeamOpen: (member) => _openTeamMemberProfile(member, deal),
              onTeamMessage: (member) async {
                final provider = await _providerForTeamMember(member);
                if (provider != null) {
                  await _startMemberChat(provider, deal: deal);
                }
              },
              onTeamRefer: (member) async {
                final provider = await _providerForTeamMember(member);
                if (provider != null) {
                  await _showReferralDialog(deal, preselected: provider);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    },
  );

  Widget _savedOpportunities() => FutureBuilder<List<MemberDealOpportunity>>(
    future: _opportunities,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const _LoadingBlock();
      final deals = snapshot.data!
          .where((deal) => _savedOpportunityIds.contains(deal.id))
          .toList();
      if (deals.isEmpty) {
        return _AccessState(
          title: 'Your watchlist is ready',
          message:
              'Open an opportunity and save it from the introduction panel. It will stay organized here while you decide whether to pitch.',
          action: 'BROWSE OPPORTUNITIES',
          onTap: () => setState(() => _view = _StudioView.opportunities),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _studioHeading(
            'WATCHLIST',
            'Saved opportunities',
            'Keep the deals that deserve a second look in one focused queue.',
          ),
          for (final deal in deals) ...[
            _DealPost(
              deal: deal,
              onOpen: () => _openOpportunity(deal),
              onPitch: () => _pitch(deal),
              onRefer: () => _showReferralDialog(deal),
              onRepost: deal.canRepost ? () => _repostDeal(deal) : null,
              onTeamOpen: (member) => _openTeamMemberProfile(member, deal),
              onTeamMessage: (member) async {
                final provider = await _providerForTeamMember(member);
                if (provider != null) {
                  await _startMemberChat(provider, deal: deal);
                }
              },
              onTeamRefer: (member) async {
                final provider = await _providerForTeamMember(member);
                if (provider != null) {
                  await _showReferralDialog(deal, preselected: provider);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    },
  );

  Widget _professionalProfileWorkspace() => FutureBuilder<MarketplaceProvider?>(
    future: _myProfessionalProfile,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingBlock();
      }
      final provider = snapshot.data;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _studioHeading(
            'MY AFFINITY PROFILE',
            provider == null ? 'Your profile' : 'Welcome, ${provider.name}',
            'Manage your private account and the professional identity connected to it. Only verified directory fields are shown to other members.',
          ),
          FutureBuilder<bool>(
            future: _creatorAccess,
            builder: (context, accessSnapshot) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE5EEE9),
                    child: SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.m34',
                      literal: false,
                      _accountInitial,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SiteText(
                          contentKey: 'copy.member_deal_marketplace_page.m35',
                          literal: false,
                          provider?.name ?? 'Affinity member',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        SiteText(
                          contentKey: 'copy.member_deal_marketplace_page.m36',
                          literal: false,
                          BackendService.user?.email ?? 'Signed-in account',
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                  _statusPill(
                    accessSnapshot.data == true
                        ? 'creator access'
                        : 'member account',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (provider == null)
            _studioPanel(
              Icons.badge_outlined,
              'Create your professional profile',
              'Add the public professional details that will appear in the directory. Affinity links the profile to this signed-in account and reviews it before publication.',
              action: 'CREATE PROFESSIONAL PROFILE',
              onTap: _openProfessionalOnboarding,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProfilePhoto(
                        size: 60,
                        photoUrl: provider.photoUrl,
                        exampleIndex: provider.photoIndex,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.m37',
                              literal: false,
                              provider.name,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.m38',
                              literal: false,
                              '${provider.jobTitle} · ${provider.company}',
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                      _statusPill(provider.verified ? 'verified' : 'in review'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _privateProfileRow(
                    'ACCOUNT',
                    BackendService.user?.email ?? 'Signed-in member',
                  ),
                  _privateProfileRow(
                    'PROFESSIONAL ROLE',
                    provider.category.label,
                  ),
                  _privateProfileRow(
                    'BACKGROUND',
                    provider.specialty.isEmpty
                        ? 'Add your background to improve recommendations'
                        : provider.specialty,
                  ),
                  _privateProfileRow(
                    'SPECIALTIES',
                    provider.specialties.isEmpty
                        ? 'Add specialties to improve recommendations'
                        : provider.specialties.join(' · '),
                  ),
                  _privateProfileRow(
                    'SERVICE AREAS',
                    provider.serviceMarkets.isEmpty
                        ? 'Add a city or region to improve recommendations'
                        : provider.serviceMarkets.join(' · '),
                  ),
                  _privateProfileRow(
                    'EXPERIENCE',
                    '${provider.experience} years',
                  ),
                  _privateProfileRow(
                    'MEMBERSHIP',
                    provider.membershipTier.toUpperCase(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openProfessionalOnboarding,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.26',
                      literal: true,
                      'UPDATE PROFILE DETAILS',
                    ),
                  ),
                ],
              ),
            ),
          if (provider != null) ...[
            const SizedBox(height: 14),
            _studioPanel(
              Icons.tune_rounded,
              'Private opportunity preferences',
              'Industries, regions, deal sizes, and services are stored against your account and used to create your personal matching feed.',
              action: 'UPDATE MATCH SETTINGS',
              onTap: _openMatchSettings,
            ),
          ],
        ],
      );
    },
  );

  String get _accountInitial {
    final email = BackendService.user?.email?.trim() ?? '';
    return email.isEmpty ? 'A' : email.substring(0, 1).toUpperCase();
  }

  Widget _privateProfileRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 150,
          child: SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m39',
            literal: false,
            label,
            style: const TextStyle(
              color: _green,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ),
        Expanded(
          child: SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m40',
            literal: false,
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Future<void> _openProfessionalOnboarding() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfessionalOnboardingPage(),
      ),
    );
    if (mounted) setState(_reload);
  }

  Widget _metricTile(String value, String label) => Container(
    constraints: const BoxConstraints(minWidth: 150),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m41',
          literal: false,
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m42',
          literal: false,
          label,
          style: const TextStyle(
            color: _green,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
      ],
    ),
  );

  Widget _studioPanel(
    IconData icon,
    String title,
    String description, {
    String? action,
    VoidCallback? onTap,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE5EEE9),
          child: Icon(icon, color: _green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SiteText(
                contentKey: 'copy.member_deal_marketplace_page.m43',
                literal: false,
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              SiteText(
                contentKey: 'copy.member_deal_marketplace_page.m44',
                literal: false,
                description,
                style: const TextStyle(color: _muted, height: 1.5),
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onTap,
                  child: SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m45',
                    literal: false,
                    action,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statusPill(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EEE9),
      borderRadius: BorderRadius.circular(30),
    ),
    child: SiteText(
      contentKey: 'copy.member_deal_marketplace_page.m46',
      literal: false,
      status.toUpperCase(),
      style: const TextStyle(
        color: _green,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

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
          action: BackendService.user == null ? 'SIGN IN' : null,
          onTap: BackendService.user == null
              ? () async {
                  if (await _ensureSignedIn() && mounted) setState(_reload);
                }
              : null,
        );
      }
      final allDeals = snapshot.data ?? [];
      if (allDeals.isEmpty) {
        return const _AccessState(
          title: 'The review desk is active',
          message:
              'Approved opportunities will appear here after Affinity completes its evaluation and privacy review.',
        );
      }
      final query = _dealQuery.trim().toLowerCase();
      final deals = allDeals.where((deal) {
        if (query.isEmpty) return true;
        return '${deal.headline} ${deal.industry} ${deal.region} ${deal.summary} ${deal.stage} ${deal.dealType}'
            .toLowerCase()
            .contains(query);
      }).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final deal in deals.take(12)) {
          MemberDealMarketplaceService.recordEngagement(deal.id, 'impression');
        }
      });
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              const title = SiteCopyText(
                'studio.opportunities_title',
                'Reviewed opportunities',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              );
              final settings = OutlinedButton.icon(
                onPressed: _openMatchSettings,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.27',
                  literal: true,
                  'MATCH SETTINGS',
                ),
              );
              if (box.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), settings],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  settings,
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          const SiteText(
            contentKey: 'copy.member_deal_marketplace_page.28',
            literal: true,
            'Current-month opportunities and highly viewed listings, prepared anonymously by Affinity.',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dealSearch,
            onChanged: (value) => setState(() => _dealQuery = value),
            decoration: InputDecoration(
              hint: SiteText(
                'Search deals by title, industry, location, or stage',
                contentKey: 'copy.member_deal_marketplace_page.mfield1',
                literal: true,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _dealQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() {
                        _dealQuery = '';
                        _dealSearch.clear();
                      }),
                      tooltip: 'Clear deal search',
                      icon: const Icon(Icons.close_rounded),
                    ),
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _line),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SiteText(
                templateValues: {
                  'value1': '${deals.length}',
                  'value2': '${deals.length == 1 ? '' : 'S'}',
                },
                contentKey: 'copy.member_deal_marketplace_page.m47',
                literal: false,
                "{{value1}} DEAL{{value2}}",
                style: const TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const Spacer(),
              const SiteText(
                contentKey: 'copy.member_deal_marketplace_page.29',
                literal: true,
                'THIS MONTH + POPULAR',
                style: TextStyle(
                  color: _muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (deals.isEmpty)
            const _AccessState(
              title: 'No deals match that search',
              message:
                  'Try an industry, a city such as Victoria, or a broader part of the deal title.',
            ),
          for (final deal in deals) ...[
            _DealPost(
              deal: deal,
              onOpen: () => _openOpportunity(deal),
              onPitch: () => _pitch(deal),
              onRefer: () => _showReferralDialog(deal),
              onRepost: deal.canRepost ? () => _repostDeal(deal) : null,
              onTeamOpen: (member) => _openTeamMemberProfile(member, deal),
              onTeamMessage: (member) async {
                final provider = await _providerForTeamMember(member);
                if (provider != null) {
                  await _startMemberChat(provider, deal: deal);
                }
              },
              onTeamRefer: (member) async {
                final provider = await _providerForTeamMember(member);
                if (provider != null) {
                  await _showReferralDialog(deal, preselected: provider);
                }
              },
            ),
            const SizedBox(height: 18),
          ],
        ],
      );
    },
  );

  Widget _professionalDirectory() => FutureBuilder<List<MarketplaceProvider>>(
    future: _professionals,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingBlock();
      }
      final query = _professionalQuery.trim().toLowerCase();
      final allProviders = snapshot.data ?? const <MarketplaceProvider>[];
      final availableRoles =
          allProviders.map((provider) => provider.category).toSet().toList()
            ..sort((a, b) => a.label.compareTo(b.label));
      final providers = allProviders
          .where(
            (provider) =>
                (_professionalRoleFilter == 'all' ||
                    provider.category.databaseValue ==
                        _professionalRoleFilter) &&
                (query.isEmpty ||
                    '${provider.name} ${provider.company}'
                        .toLowerCase()
                        .contains(query)),
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SiteCopyText(
            'studio.professionals_title',
            'Verified professionals',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          const SiteCopyText(
            'studio.professionals_intro',
            'Find the people buyers may need across financing, diligence, legal, tax, insurance, operations, and transition.',
            style: TextStyle(color: _muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final search = TextField(
                controller: _professionalSearch,
                onChanged: (value) =>
                    setState(() => _professionalQuery = value),
                decoration: InputDecoration(
                  hint: SiteText(
                    'Search a person or company',
                    contentKey: 'copy.member_deal_marketplace_page.mfield2',
                    literal: true,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _professionalQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(() {
                            _professionalQuery = '';
                            _professionalSearch.clear();
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              );
              final roleFilter = DropdownButtonFormField<String>(
                initialValue: _professionalRoleFilter,
                isExpanded: true,
                decoration: InputDecoration(
                  label: SiteText(
                    'Professional role',
                    contentKey: 'copy.member_deal_marketplace_page.mfield3',
                    literal: true,
                  ),
                  prefixIcon: const Icon(Icons.filter_list_rounded),
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: SiteText(
                      contentKey: 'copy.member_deal_marketplace_page.m48',
                      literal: true,
                      'All professional roles',
                    ),
                  ),
                  for (final role in availableRoles)
                    DropdownMenuItem(
                      value: role.databaseValue,
                      child: SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.m49',
                        literal: false,
                        role.label,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _professionalRoleFilter = value ?? 'all'),
              );
              if (box.maxWidth < 650) {
                return Column(
                  children: [search, const SizedBox(height: 10), roleFilter],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: roleFilter),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SiteText(
                templateValues: {
                  'value1': '${providers.length}',
                  'value2': '${providers.length == 1 ? '' : 'S'}',
                },
                contentKey: 'copy.member_deal_marketplace_page.m50',
                literal: false,
                "{{value1}} VERIFIED PROFESSIONAL{{value2}}",
                style: const TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (_professionalRoleFilter != 'all' || query.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _professionalQuery = '';
                    _professionalSearch.clear();
                    _professionalRoleFilter = 'all';
                  }),
                  child: const SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.30',
                    literal: true,
                    'CLEAR FILTERS',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (providers.isEmpty)
            const _AccessState(
              title: 'No matching professionals yet',
              message:
                  'Try a broader specialty or check back as the verified network grows.',
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth >= 680
                    ? (box.maxWidth - 14) / 2
                    : box.maxWidth;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final provider in providers)
                      SizedBox(
                        width: width,
                        child: _ProfessionalCard(
                          provider: provider,
                          onMessage: provider.isExample
                              ? null
                              : () => _startMemberChat(
                                  provider,
                                  deal: _selectedOpportunity,
                                ),
                          onRefer: _selectedOpportunity == null
                              ? null
                              : () => _showReferralDialog(
                                  _selectedOpportunity!,
                                  preselected: provider,
                                ),
                        ),
                      ),
                  ],
                );
              },
            ),
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
      final allPitches = snapshot.data ?? [];
      final pitches = buyerView && _responseFilter != 'all'
          ? allPitches
                .where((pitch) => pitch.status == _responseFilter)
                .toList()
          : allPitches;
      if (allPitches.isEmpty) {
        return _AccessState(
          title: buyerView ? 'No deal responses yet' : 'No pitches yet',
          message: buyerView
              ? 'When a verified member responds to your published deal, their short pitch and contact details appear here.'
              : 'Review an approved opportunity and send a concise, specific proposal. Your contact details go to the buyer—not the other way around.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (buyerView) ...[
            const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.31',
              literal: true,
              'Compare private pitches',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 7),
            const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.32',
              literal: true,
              'Shortlist promising professionals before sharing your identity. Only acceptance releases your account email.',
              style: TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _responseChip('all', 'ALL ${allPitches.length}'),
                _responseChip(
                  'submitted',
                  'NEW ${allPitches.where((p) => p.status == 'submitted').length}',
                ),
                _responseChip(
                  'shortlisted',
                  'SHORTLIST ${allPitches.where((p) => p.status == 'shortlisted').length}',
                ),
                _responseChip(
                  'accepted',
                  'CONNECTED ${allPitches.where((p) => p.status == 'accepted').length}',
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (pitches.isEmpty)
            const _AccessState(
              title: 'No pitches in this view',
              message:
                  'Choose another response filter to compare your private proposals.',
            ),
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

  Widget _responseChip(String value, String label) => ChoiceChip(
    label: SiteText(
      contentKey: 'copy.member_deal_marketplace_page.m51',
      literal: false,
      label,
    ),
    selected: _responseFilter == value,
    selectedColor: _green,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: _responseFilter == value ? Colors.white : _ink,
      fontSize: 9,
      fontWeight: FontWeight.w900,
    ),
    onSelected: (_) => setState(() => _responseFilter = value),
  );
}

class _BriefSection extends StatelessWidget {
  const _BriefSection({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 150),
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green, size: 22),
        const SizedBox(height: 14),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m52',
          literal: false,
          label,
          style: const TextStyle(
            color: _green,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
        const SizedBox(height: 8),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m53',
          literal: false,
          value,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    ),
  );
}

class _DealTeamStrip extends StatelessWidget {
  const _DealTeamStrip({
    required this.members,
    required this.onOpen,
    required this.onMessage,
    required this.onRefer,
  });

  final List<MemberDealTeamMember> members;
  final ValueChanged<MemberDealTeamMember> onOpen;
  final ValueChanged<MemberDealTeamMember> onMessage;
  final ValueChanged<MemberDealTeamMember> onRefer;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const SiteText(
            contentKey: 'copy.member_deal_marketplace_page.33',
            literal: true,
            'CURRENT DEAL TEAM',
            style: TextStyle(
              color: _green,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (members.isNotEmpty)
            const Row(
              children: [
                SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.m54',
                  literal: true,
                  'SCROLL',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.swap_horiz_rounded, size: 16, color: _muted),
              ],
            ),
        ],
      ),
      const SizedBox(height: 10),
      if (members.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3EF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const SiteText(
            contentKey: 'copy.member_deal_marketplace_page.34',
            literal: true,
            'No professionals have joined this deal yet.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        )
      else
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final member = members[index];
              return Material(
                color: const Color(0xFFF1F3EF),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onOpen(member),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E5DF)),
                    ),
                    child: Row(
                      children: [
                        ProfilePhoto(
                          size: 46,
                          photoUrl: member.photoUrl,
                          exampleIndex: member.photoIndex,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SiteText(
                                contentKey:
                                    'copy.member_deal_marketplace_page.m55',
                                literal: false,
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              SiteText(
                                contentKey:
                                    'copy.member_deal_marketplace_page.m56',
                                literal: false,
                                member.jobTitle.isEmpty
                                    ? _roleLabel(member.providerType)
                                    : member.jobTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (member.company.isNotEmpty)
                                SiteText(
                                  contentKey:
                                      'copy.member_deal_marketplace_page.m57',
                                  literal: false,
                                  member.company,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _teamAction(
                              Icons.chat_bubble_outline_rounded,
                              'Message member',
                              () => onMessage(member),
                            ),
                            _teamAction(
                              Icons.person_add_alt_1_outlined,
                              'Refer member',
                              () => onRefer(member),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );

  static Widget _teamAction(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) => SizedBox.square(
    dimension: 29,
    child: IconButton(
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: _green),
    ),
  );

  static String _roleLabel(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _DealPost extends StatelessWidget {
  const _DealPost({
    required this.deal,
    required this.onOpen,
    required this.onPitch,
    required this.onRefer,
    this.onRepost,
    required this.onTeamOpen,
    required this.onTeamMessage,
    required this.onTeamRefer,
  });
  final MemberDealOpportunity deal;
  final VoidCallback onOpen;
  final VoidCallback onPitch;
  final VoidCallback onRefer;
  final VoidCallback? onRepost;
  final ValueChanged<MemberDealTeamMember> onTeamOpen;
  final ValueChanged<MemberDealTeamMember> onTeamMessage;
  final ValueChanged<MemberDealTeamMember> onTeamRefer;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: const Color(0xFFE2E5DF)),
          borderRadius: BorderRadius.circular(22),
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
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.m58',
                        literal: true,
                        'ANONYMOUS BUYER',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: .8,
                        ),
                      ),
                      SizedBox(height: 4),
                      SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.m59',
                        literal: true,
                        'Identity protected · Affinity reviewed',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _Score(
                  score: deal.matchScore ?? deal.affinityScore,
                  label: deal.matchScore == null ? 'DEAL' : 'MATCH',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m60',
              literal: false,
              deal.headline,
              style: const TextStyle(
                fontSize: 28,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 9),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m61',
              literal: false,
              '${deal.industry} · ${deal.region} · ${deal.stage}',
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m62',
              literal: false,
              deal.summary,
              style: const TextStyle(height: 1.6, fontSize: 15),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 20,
              runSpacing: 14,
              children: [
                _Fact(label: 'LOCATION', value: deal.region),
                _Fact(label: 'INDUSTRY', value: deal.industry),
                _Fact(label: 'PRICE RANGE', value: deal.purchasePriceBand),
                _Fact(label: 'STAGE', value: deal.stage),
              ],
            ),
            const SizedBox(height: 22),
            _DealTeamStrip(
              members: deal.teamMembers,
              onOpen: onTeamOpen,
              onMessage: onTeamMessage,
              onRefer: onTeamRefer,
            ),
            const SizedBox(height: 22),
            if (deal.trafficCount > 0) ...[
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_outlined,
                    size: 16,
                    color: _green,
                  ),
                  const SizedBox(width: 6),
                  SiteText(
                    templateValues: {
                      'value1': '${deal.trafficCount}',
                      'value2': '${deal.trafficCount == 1 ? '' : 's'}',
                    },
                    contentKey: 'copy.member_deal_marketplace_page.m63',
                    literal: false,
                    "{{value1}} recent marketplace interaction{{value2}}",
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 210,
                  child: SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m64',
                    literal: false,
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
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.35',
                        literal: true,
                        'VIEW FULL DEAL',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onRefer,
                      icon: const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 17,
                      ),
                      label: const SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.36',
                        literal: true,
                        'REFER A MEMBER',
                      ),
                    ),
                    if (onRepost != null)
                      FilledButton.tonalIcon(
                        onPressed: onRepost,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const SiteText(
                          contentKey: 'copy.member_deal_marketplace_page.37',
                          literal: true,
                          'REPOST TO TOP',
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: deal.canContact ? onPitch : null,
                      style: FilledButton.styleFrom(backgroundColor: _green),
                      icon: Icon(
                        deal.canContact
                            ? Icons.send_outlined
                            : Icons.person_off_outlined,
                        size: 18,
                      ),
                      label: SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.m65',
                        literal: false,
                        deal.canContact
                            ? 'PITCH THIS DEAL'
                            : 'ROLE ALREADY FILLED',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
          content: SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m66',
            literal: true,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m67',
              literal: false,
              _friendlyError(error),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const SiteText(
      contentKey: 'copy.member_deal_marketplace_page.38',
      literal: true,
      'Pitch the anonymous buyer',
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m68',
              literal: false,
              widget.deal.headline,
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _pitch,
              maxLength: 420,
              maxLines: 5,
              decoration: const InputDecoration(
                label: SiteText(
                  'Your pitch',
                  contentKey: 'copy.member_deal_marketplace_page.field6',
                  literal: true,
                ),
                hint: SiteText(
                  'Explain what you can offer, why it fits this deal, and the next useful step.',
                  contentKey: 'copy.member_deal_marketplace_page.field7',
                  literal: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _offer,
              maxLength: 120,
              decoration: const InputDecoration(
                label: SiteText(
                  'Offer summary',
                  contentKey: 'copy.member_deal_marketplace_page.field8',
                  literal: true,
                ),
                hint: SiteText(
                  'Example: Indicative loan from 8%, subject to review',
                  contentKey: 'copy.member_deal_marketplace_page.field9',
                  literal: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                label: SiteText(
                  'Your reply email',
                  contentKey: 'copy.member_deal_marketplace_page.field10',
                  literal: true,
                ),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: const SiteText(
                contentKey: 'copy.member_deal_marketplace_page.39',
                literal: true,
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
        child: const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.40',
          literal: true,
          'CANCEL',
        ),
      ),
      FilledButton(
        onPressed: _sending ? null : _send,
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m69',
          literal: false,
          _sending ? 'SENDING…' : 'SEND PRIVATE PITCH',
        ),
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
      border: Border.all(color: const Color(0xFFE2E5DF)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SiteText(
                contentKey: 'copy.member_deal_marketplace_page.m70',
                literal: false,
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
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m71',
          literal: false,
          buyerView ? pitch.providerType : 'Anonymous buyer',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m72',
          literal: false,
          pitch.pitch,
          style: const TextStyle(height: 1.55),
        ),
        if (pitch.offerSummary.isNotEmpty) ...[
          const SizedBox(height: 14),
          SiteText(
            contentKey: 'copy.member_deal_marketplace_page.m73',
            literal: false,
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
        if (buyerView &&
            (pitch.status == 'submitted' || pitch.status == 'shortlisted')) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            children: [
              if (pitch.status == 'submitted')
                OutlinedButton.icon(
                  onPressed: () => onRespond?.call('shortlisted'),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                  label: const SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.41',
                    literal: true,
                    'SHORTLIST',
                  ),
                ),
              FilledButton(
                onPressed: () => onRespond?.call('accepted'),
                style: FilledButton.styleFrom(backgroundColor: _green),
                child: const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.42',
                  literal: true,
                  'ACCEPT & SHARE MY EMAIL',
                ),
              ),
              OutlinedButton(
                onPressed: () => onRespond?.call('declined'),
                child: const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.43',
                  literal: true,
                  'DECLINE',
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _MatchSettingsDialog extends StatefulWidget {
  const _MatchSettingsDialog({required this.current});
  final AffinityMatchPreferences current;

  @override
  State<_MatchSettingsDialog> createState() => _MatchSettingsDialogState();
}

class _MatchSettingsDialogState extends State<_MatchSettingsDialog> {
  late final TextEditingController specialties;
  late final TextEditingController regions;
  late double minimumScore;
  late bool emailNotifications;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    specialties = TextEditingController(
      text: widget.current.specialties.join(', '),
    );
    regions = TextEditingController(text: widget.current.regions.join(', '));
    minimumScore = widget.current.minimumScore.toDouble();
    emailNotifications = widget.current.emailNotifications;
  }

  @override
  void dispose() {
    specialties.dispose();
    regions.dispose();
    super.dispose();
  }

  List<String> _split(String value) => value
      .split(RegExp(r'[,\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await MemberBetaService.savePreferences(
        AffinityMatchPreferences(
          specialties: _split(specialties.text),
          regions: _split(regions.text),
          minimumScore: minimumScore.round(),
          emailNotifications: emailNotifications,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m74',
              literal: false,
              _friendlyError(error),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const SiteText(
      contentKey: 'copy.member_deal_marketplace_page.44',
      literal: true,
      'Opportunity match settings',
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.45',
              literal: true,
              'Affinity uses these preferences to rank and filter anonymous opportunities. They are never shown to buyers.',
              style: TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: specialties,
              maxLines: 2,
              decoration: const InputDecoration(
                label: SiteText(
                  'Expertise',
                  contentKey: 'copy.member_deal_marketplace_page.field11',
                  literal: true,
                ),
                hint: SiteText(
                  'Commercial lending, QOE, M&A legal',
                  contentKey: 'copy.member_deal_marketplace_page.field12',
                  literal: true,
                ),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: regions,
              maxLines: 2,
              decoration: const InputDecoration(
                label: SiteText(
                  'Regions',
                  contentKey: 'copy.member_deal_marketplace_page.field13',
                  literal: true,
                ),
                hint: SiteText(
                  'British Columbia, Alberta',
                  contentKey: 'copy.member_deal_marketplace_page.field14',
                  literal: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SiteText(
              templateValues: {'value1': '${minimumScore.round()}'},
              contentKey: 'copy.member_deal_marketplace_page.m75',
              literal: false,
              "Minimum Affinity score · {{value1}}",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              value: minimumScore,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: _green,
              onChanged: (value) => setState(() => minimumScore = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: emailNotifications,
              activeThumbColor: _green,
              title: const SiteText(
                contentKey: 'copy.member_deal_marketplace_page.46',
                literal: true,
                'Email me about private activity',
              ),
              subtitle: const SiteText(
                contentKey: 'copy.member_deal_marketplace_page.47',
                literal: true,
                'Deal matches and pitch decisions only.',
              ),
              onChanged: (value) => setState(() => emailNotifications = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.48',
          literal: true,
          'CANCEL',
        ),
      ),
      FilledButton(
        onPressed: saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m76',
          literal: false,
          saving ? 'SAVING…' : 'SAVE MATCH SETTINGS',
        ),
      ),
    ],
  );
}

class _ReferralDialog extends StatefulWidget {
  const _ReferralDialog({
    required this.deal,
    required this.providers,
    this.preselected,
  });

  final MemberDealOpportunity deal;
  final List<MarketplaceProvider> providers;
  final MarketplaceProvider? preselected;

  @override
  State<_ReferralDialog> createState() => _ReferralDialogState();
}

class _ReferralDialogState extends State<_ReferralDialog> {
  final note = TextEditingController();
  String? providerId;

  @override
  void initState() {
    super.initState();
    providerId = widget.preselected?.id;
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const SiteText(
      contentKey: 'copy.member_deal_marketplace_page.49',
      literal: true,
      'Refer a member to this deal',
    ),
    content: SizedBox(
      width: 540,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.50',
                  literal: true,
                  'ANONYMOUS OPPORTUNITY',
                  style: TextStyle(
                    color: _green,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 5),
                SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.m77',
                  literal: false,
                  widget.deal.headline,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.m78',
                  literal: false,
                  widget.deal.region,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: providerId,
            isExpanded: true,
            decoration: const InputDecoration(
              label: SiteText(
                'Member to refer',
                contentKey: 'copy.member_deal_marketplace_page.field15',
                literal: true,
              ),
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
            items: [
              for (final provider in widget.providers)
                DropdownMenuItem(
                  value: provider.id,
                  child: SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m79',
                    literal: false,
                    '${provider.name} · ${provider.jobTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => providerId = value),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: note,
            minLines: 3,
            maxLines: 5,
            maxLength: 600,
            decoration: const InputDecoration(
              label: SiteText(
                'Why they are a good fit (optional)',
                contentKey: 'copy.member_deal_marketplace_page.field16',
                literal: true,
              ),
              hint: SiteText(
                'Add useful context for the member you are referring.',
                contentKey: 'copy.member_deal_marketplace_page.field17',
                literal: true,
              ),
            ),
          ),
          const SiteText(
            contentKey: 'copy.member_deal_marketplace_page.51',
            literal: true,
            'The member sees the anonymous deal brief—not the buyer’s identity. A referral cannot override a professional role that is already filled.',
            style: TextStyle(color: _muted, fontSize: 10, height: 1.45),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.52',
          literal: true,
          'CANCEL',
        ),
      ),
      FilledButton.icon(
        onPressed: providerId == null
            ? null
            : () {
                final provider = widget.providers
                    .where((item) => item.id == providerId)
                    .firstOrNull;
                if (provider != null) {
                  Navigator.pop(context, (
                    provider: provider,
                    note: note.text.trim(),
                  ));
                }
              },
        style: FilledButton.styleFrom(backgroundColor: _green),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
        label: const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.53',
          literal: true,
          'SEND REFERRAL',
        ),
      ),
    ],
  );
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.provider,
    required this.onMessage,
    this.onRefer,
  });
  final MarketplaceProvider provider;
  final Future<void> Function()? onMessage;
  final Future<void> Function()? onRefer;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemberProfilePage(
            provider: provider,
            onMessage: onMessage,
            onRefer: onRefer,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfilePhoto(
                  size: 56,
                  photoUrl: provider.photoUrl,
                  exampleIndex: provider.photoIndex,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.m80',
                              literal: false,
                              provider.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (provider.verified) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              color: _green,
                              size: 17,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      SiteText(
                        contentKey: 'copy.member_deal_marketplace_page.m81',
                        literal: false,
                        provider.jobTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m82',
              literal: false,
              provider.company.isEmpty
                  ? provider.category.label
                  : provider.company,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            if (provider.specialty.isNotEmpty) ...[
              const SizedBox(height: 7),
              SiteText(
                contentKey: 'copy.member_deal_marketplace_page.m83',
                literal: false,
                provider.specialty,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EEE9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SiteText(
                    contentKey: 'copy.member_deal_marketplace_page.m84',
                    literal: false,
                    provider.category.label.toUpperCase(),
                    style: const TextStyle(
                      color: _green,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const Spacer(),
                if (onMessage != null)
                  IconButton(
                    onPressed: onMessage,
                    tooltip: 'Message ${provider.name}',
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: _green,
                    ),
                  ),
                if (onRefer != null)
                  IconButton(
                    onPressed: onRefer,
                    tooltip: 'Refer to selected deal',
                    icon: const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 18,
                      color: _green,
                    ),
                  ),
                const SiteText(
                  contentKey: 'copy.member_deal_marketplace_page.54',
                  literal: true,
                  'VIEW PROFILE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Score extends StatelessWidget {
  const _Score({required this.score, this.label = 'SCORE'});
  final int score;
  final String label;
  @override
  Widget build(BuildContext context) {
    final boundedScore = score.clamp(1, 99);
    final color = scoreColor(boundedScore);
    return Tooltip(
      message:
          '$label score $boundedScore of 99 · red is low, orange is mid-range, green is high',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .22), blurRadius: 12),
          ],
        ),
        child: Column(
          children: [
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m85',
              literal: false,
              '$boundedScore',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m86',
              literal: false,
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m87',
          literal: false,
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 5),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m88',
          literal: false,
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class BusinessSaleBulletinPage extends StatefulWidget {
  const BusinessSaleBulletinPage({super.key});

  @override
  State<BusinessSaleBulletinPage> createState() =>
      _BusinessSaleBulletinPageState();
}

class _BusinessSaleBulletinPageState extends State<BusinessSaleBulletinPage> {
  late Future<List<BusinessSaleBulletin>> _bulletins;
  late Future<bool> _isAdmin;
  late Future<Map<String, dynamic>> _buyerFoundation;
  final _bulletinSearch = TextEditingController();
  String _searchQuery = '';
  String _priceFilter = 'all';
  String _sort = 'match';
  bool _savedOnly = false;
  final Set<String> _savingIds = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _bulletins = BusinessSaleBulletinService.load();
    _isAdmin = AffinityAdminService.isAdmin();
    _buyerFoundation = AccountService.loadAcquisitionFoundation().then(
      (value) => value ?? const <String, dynamic>{},
    );
  }

  @override
  void dispose() {
    _bulletinSearch.dispose();
    super.dispose();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: SiteText(
        contentKey: 'copy.member_deal_marketplace_page.m89',
        literal: false,
        text,
      ),
    ),
  );

  Future<void> _addBusiness() => _editBusiness();

  Future<void> _editBusiness([BusinessSaleBulletin? bulletin]) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BulletinListingEditor(initial: bulletin),
      ),
    );
    if (id != null && mounted) {
      setState(_reload);
      _message(
        bulletin == null
            ? 'Business published.'
            : 'Listing updated. Only accounts that saved it receive an update.',
      );
    }
  }

  Future<void> _openListing(BusinessSaleBulletin b) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessListingDetailPage(bulletinId: b.id),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _toggleSaved(BusinessSaleBulletin b) async {
    if (_savingIds.contains(b.id)) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() => _savingIds.add(b.id));
    try {
      final fresh = await BusinessSaleBulletinService.loadOne(b.id);
      if (fresh == null) throw StateError('This listing is unavailable.');
      await BusinessSaleBulletinService.setSaved(b.id, !fresh.isSaved);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) _message(_bulletinError(e));
    } finally {
      if (mounted) setState(() => _savingIds.remove(b.id));
    }
  }

  Future<void> _makeAnonymousDeal(BusinessSaleBulletin bulletin) async {
    final draft = await showDialog<_AnonymousDealDraft>(
      context: context,
      builder: (_) => _AnonymousDealDialog(bulletin: bulletin),
    );
    if (draft == null || !mounted) return;
    try {
      await BusinessSaleBulletinService.makeAnonymousDeal(
        bulletinId: bulletin.id,
        headline: draft.headline,
        summary: draft.summary,
      );
      if (!mounted) return;
      setState(_reload);
      _message('Anonymous deal draft created in Review Desk.');
    } catch (error) {
      if (mounted) _message(_bulletinError(error));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE7ECFF),
    appBar: AppBar(
      toolbarHeight: 72,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 52, dark: false),
      actions: [
        IconButton(
          onPressed: () => setState(_reload),
          tooltip: 'Refresh bulletin board',
          icon: const Icon(Icons.refresh_rounded),
        ),
        const AppNavigationMenu(side: PlatformSide.business, dark: false),
        const SizedBox(width: 10),
      ],
    ),
    body: FutureBuilder<List<BusinessSaleBulletin>>(
      future: _bulletins,
      builder: (context, snapshot) => FutureBuilder<Map<String, dynamic>>(
        future: _buyerFoundation,
        builder: (context, foundationSnapshot) {
          final foundation = foundationSnapshot.data ?? const {};
          final blueprint = foundation['blueprint'] is Map
              ? Map<String, dynamic>.from(foundation['blueprint'] as Map)
              : const <String, dynamic>{};
          final rawProfile = blueprint['comparisonProfile'];
          final profile = rawProfile is Map
              ? BuyerComparisonProfile.fromJson(
                  Map<String, dynamic>.from(rawProfile),
                )
              : const BuyerComparisonProfile();
          final matcher = BuyerDealMatcher(
            profile: profile,
            blueprint: blueprint,
          );
          final hasPreferences =
              profile.answeredCount > 0 ||
              [
                'industries',
                'geography',
                'minPrice',
                'maxPrice',
              ].any((key) => '${blueprint[key] ?? ''}'.trim().isNotEmpty);
          final query = _searchQuery.trim().toLowerCase();
          final visible = (snapshot.data ?? const <BusinessSaleBulletin>[]).where((
            bulletin,
          ) {
            final text =
                '${bulletin.title} ${bulletin.industry} ${bulletin.region} ${bulletin.summary}'
                    .toLowerCase();
            return (!_savedOnly || bulletin.isSaved) &&
                (query.isEmpty ||
                    query.split(RegExp(r'\s+')).every(text.contains)) &&
                BuyerDealMatcher.matchesPriceFilter(
                  bulletin.askingPriceBand,
                  _priceFilter,
                );
          }).toList();
          if (hasPreferences && _sort == 'match') {
            visible.sort(
              (a, b) => matcher
                  .score(
                    title: b.title,
                    industry: b.industry,
                    region: b.region,
                    askingPriceBand: b.askingPriceBand,
                    summary: b.summary,
                  )
                  .compareTo(
                    matcher.score(
                      title: a.title,
                      industry: a.industry,
                      region: a.region,
                      askingPriceBand: a.askingPriceBand,
                      summary: a.summary,
                    ),
                  ),
            );
          }
          if (_sort == 'newest') {
            visible.sort((a, b) => b.postedAt.compareTo(a.postedAt));
          }
          if (_sort == 'updated') {
            visible.sort(
              (a, b) => (b.updatedAt ?? b.postedAt).compareTo(
                a.updatedAt ?? a.postedAt,
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 38, 20, 70),
            child: Center(
              child: SizedBox(
                width: 1040,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, box) {
                        const heading = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.m90',
                              literal: true,
                              'BUSINESSES FOR SALE',
                              style: TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                              ),
                            ),
                            SizedBox(height: 10),
                            SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.m91',
                              literal: true,
                              'Bulletin board',
                              style: TextStyle(
                                fontSize: 42,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.6,
                              ),
                            ),
                            SizedBox(height: 12),
                            SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.m92',
                              literal: true,
                              'Find your next business. Browse freely, save your favourites, and follow only the updates that matter to you.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        );
                        final addButton = FutureBuilder<bool>(
                          future: _isAdmin,
                          builder: (context, admin) => admin.data == true
                              ? FilledButton.icon(
                                  onPressed: _addBusiness,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _green,
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const SiteText(
                                    contentKey:
                                        'copy.member_deal_marketplace_page.55',
                                    literal: true,
                                    'ADD BUSINESS',
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
                        if (box.maxWidth < 650) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              heading,
                              const SizedBox(height: 18),
                              addButton,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(child: heading),
                            const SizedBox(width: 20),
                            addButton,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFD5DDF8)),
                      ),
                      child: _bulletinFilters(),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SiteText(
                          templateValues: {'value1': '${visible.length}'},
                          contentKey: 'copy.member_deal_marketplace_page.m93',
                          literal: false,
                          "{{value1}} businesses",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (BackendService.user != null)
                          FilterChip(
                            label: const SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.56',
                              literal: true,
                              'Saved businesses',
                            ),
                            selected: _savedOnly,
                            onSelected: (value) =>
                                setState(() => _savedOnly = value),
                          ),
                        SizedBox(
                          width: 240,
                          child: DropdownButtonFormField<String>(
                            initialValue: _sort,
                            decoration: const InputDecoration(
                              label: SiteText(
                                'Sort by',
                                contentKey:
                                    'copy.member_deal_marketplace_page.field18',
                                literal: true,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'match',
                                child: SiteText(
                                  contentKey:
                                      'copy.member_deal_marketplace_page.m94',
                                  literal: true,
                                  'Best matches',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'newest',
                                child: SiteText(
                                  contentKey:
                                      'copy.member_deal_marketplace_page.m95',
                                  literal: true,
                                  'Newest listings',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'updated',
                                child: SiteText(
                                  contentKey:
                                      'copy.member_deal_marketplace_page.m96',
                                  literal: true,
                                  'Recently updated',
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _sort = value ?? 'match'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (BackendService.user != null && hasPreferences)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.57',
                              literal: true,
                              'PERSONALIZED FOR YOUR SAVED BUYER PROFILE · BEST MATCHES FIRST',
                              style: TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const SiteText(
                              contentKey:
                                  'copy.member_deal_marketplace_page.58',
                              literal: true,
                              'Deal scores estimate interest fit from the listing details available. Financial diligence still determines whether a business is viable.',
                              style: TextStyle(color: _muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const _LoadingBlock()
                    else if (snapshot.hasError)
                      _AccessState(
                        title: 'Bulletin board unavailable',
                        message: _bulletinError(snapshot.error!),
                      )
                    else if (visible.isEmpty)
                      _AccessState(
                        title: query.isEmpty && _priceFilter == 'all'
                            ? 'No businesses posted yet'
                            : 'No businesses match those filters',
                        message: query.isEmpty && _priceFilter == 'all'
                            ? 'New business-for-sale listings will appear here as they are added.'
                            : 'Try a broader name, theme, location, or price range.',
                      )
                    else
                      for (final bulletin in visible) ...[
                        BulletinMarketplaceCard(
                          bulletin: bulletin,
                          dealScore: hasPreferences
                              ? matcher.score(
                                  title: bulletin.title,
                                  industry: bulletin.industry,
                                  region: bulletin.region,
                                  askingPriceBand: bulletin.askingPriceBand,
                                  summary: bulletin.summary,
                                )
                              : null,
                          onOpen: () => _openListing(bulletin),
                          onSave: _savingIds.contains(bulletin.id)
                              ? null
                              : () => _toggleSaved(bulletin),
                          onEdit: bulletin.canEdit
                              ? () => _editBusiness(bulletin)
                              : null,
                          onConvert: bulletin.canConvert
                              ? () => _makeAnonymousDeal(bulletin)
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _bulletinFilters() => LayoutBuilder(
    builder: (context, box) {
      final search = TextField(
        controller: _bulletinSearch,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          label: SiteText(
            'Search businesses',
            contentKey: 'copy.member_deal_marketplace_page.mfield4',
            literal: true,
          ),
          hint: SiteText(
            'Business name, location, industry, or theme',
            contentKey: 'copy.member_deal_marketplace_page.mfield5',
            literal: true,
          ),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _bulletinSearch.clear();
                  }),
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      );
      final price = DropdownButtonFormField<String>(
        initialValue: _priceFilter,
        decoration: const InputDecoration(
          label: SiteText(
            'Price range',
            contentKey: 'copy.member_deal_marketplace_page.field19',
            literal: true,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'all',
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m97',
              literal: true,
              'All prices',
            ),
          ),
          DropdownMenuItem(
            value: 'under-500k',
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m98',
              literal: true,
              r'Under $500K',
            ),
          ),
          DropdownMenuItem(
            value: '500k-1m',
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m99',
              literal: true,
              r'$500K–$1M',
            ),
          ),
          DropdownMenuItem(
            value: '1m-2m',
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m100',
              literal: true,
              r'$1M–$2M',
            ),
          ),
          DropdownMenuItem(
            value: '2m-5m',
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m101',
              literal: true,
              r'$2M–$5M',
            ),
          ),
          DropdownMenuItem(
            value: '5m-plus',
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m102',
              literal: true,
              r'$5M+',
            ),
          ),
          DropdownMenuItem(
            value: 'unlisted',
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m103',
              literal: true,
              'Price not listed',
            ),
          ),
        ],
        onChanged: (value) => setState(() => _priceFilter = value ?? 'all'),
      );
      if (box.maxWidth < 680) {
        return Column(children: [search, const SizedBox(height: 12), price]);
      }
      return Row(
        children: [
          Expanded(flex: 2, child: search),
          const SizedBox(width: 12),
          Expanded(child: price),
        ],
      );
    },
  );
}

String _bulletinError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '');
  if (text.contains('Could not find the function') ||
      text.contains('does not exist')) {
    return 'The bulletin board database migration still needs to be applied.';
  }
  return text;
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
    child: SiteText(
      contentKey: 'copy.member_deal_marketplace_page.m104',
      literal: false,
      status.toUpperCase(),
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _AnonymousDealDraft {
  const _AnonymousDealDraft({required this.headline, required this.summary});
  final String headline;
  final String summary;
}

class _AnonymousDealDialog extends StatefulWidget {
  const _AnonymousDealDialog({required this.bulletin});
  final BusinessSaleBulletin bulletin;

  @override
  State<_AnonymousDealDialog> createState() => _AnonymousDealDialogState();
}

class _AnonymousDealDialogState extends State<_AnonymousDealDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _headline;
  late final TextEditingController _summary;

  @override
  void initState() {
    super.initState();
    final industry = widget.bulletin.industry.trim().isEmpty
        ? 'business'
        : widget.bulletin.industry.trim();
    final region = widget.bulletin.region.trim().isEmpty
        ? 'an undisclosed region'
        : widget.bulletin.region.trim();
    _headline = TextEditingController(
      text: 'Established $industry opportunity',
    );
    _summary = TextEditingController(
      text:
          'An established $industry business in $region is available for acquisition. Affinity is preparing this opportunity for private member review and further diligence.',
    );
  }

  @override
  void dispose() {
    _headline.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _AnonymousDealDraft(headline: _headline.text, summary: _summary.text),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const SiteText(
      contentKey: 'copy.member_deal_marketplace_page.59',
      literal: true,
      'Make an anonymous deal',
    ),
    content: SizedBox(
      width: 580,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SiteText(
              contentKey: 'copy.member_deal_marketplace_page.60',
              literal: true,
              'Review this public copy carefully. Do not include the business name, source, address, or identifying details. The result stays private in Review Desk until approved.',
              style: TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _headline,
              decoration: const InputDecoration(
                label: SiteText(
                  'Anonymous headline',
                  contentKey: 'copy.member_deal_marketplace_page.field20',
                  literal: true,
                ),
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value?.trim().length ?? 0) < 8
                  ? 'Enter at least 8 characters'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summary,
              maxLines: 5,
              decoration: const InputDecoration(
                label: SiteText(
                  'Anonymous summary',
                  contentKey: 'copy.member_deal_marketplace_page.field21',
                  literal: true,
                ),
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value?.trim().length ?? 0) < 40
                  ? 'Enter at least 40 characters'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.61',
          literal: true,
          'CANCEL',
        ),
      ),
      FilledButton(
        onPressed: _submit,
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: const SiteText(
          contentKey: 'copy.member_deal_marketplace_page.62',
          literal: true,
          'CREATE REVIEW DRAFT',
        ),
      ),
    ],
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
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(Icons.info_outline_rounded, color: _green, size: 32),
        const SizedBox(height: 14),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m105',
          literal: false,
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        SiteText(
          contentKey: 'copy.member_deal_marketplace_page.m106',
          literal: false,
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        if (action != null && onTap != null) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: SiteText(
              contentKey: 'copy.member_deal_marketplace_page.m107',
              literal: false,
              action!,
            ),
          ),
        ],
      ],
    ),
  );
}

String _friendlyError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '');
  if (text.contains('verified Affinity member') ||
      text.contains('Verified member access required')) {
    return 'A verified, active professional membership is required to browse and pitch opportunities.';
  }
  if (text.contains('professional role is already filled') ||
      text.contains('already has a')) {
    return 'That buyer already has someone in your professional role for this deal. You can still contact them about a different opportunity.';
  }
  if (text.contains('You cannot message yourself')) {
    return 'This is your profile. Choose another member to message.';
  }
  if (text.contains('Could not find the function') ||
      text.contains('does not exist')) {
    return 'The Member Studio backend migration still needs to be applied.';
  }
  return text;
}
