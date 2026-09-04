import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/platform_side.dart';
import '../services/member_beta_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/membership_footer.dart';
import 'affinity_review_desk_page.dart';
import 'member_deal_marketplace_page.dart';
import 'profile_page.dart';

const _green = Color(0xFF053827);
const _muted = Color(0xFF68635D);

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  late Future<List<AffinityNotification>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = MemberBetaService.loadNotifications();
    MemberBetaService.flushEmailOutbox();
  }

  Future<void> _open(AffinityNotification item) async {
    await MemberBetaService.markRead(item.id);
    if (!mounted) return;
    setState(() {
      _notifications = _notifications.then(
        (items) => items.where((candidate) => candidate.id != item.id).toList(),
      );
    });
    final page = switch (item.actionModule) {
      'review-desk' => const AffinityReviewDeskPage(),
      'profile' => const ProfilePage(),
      _ => const MemberDealMarketplacePage(),
    };
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) {
      setState(() => _notifications = MemberBetaService.loadNotifications());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F3EF),
    appBar: AppBar(
      toolbarHeight: 78,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: _green,
            padding: const EdgeInsets.fromLTRB(24, 62, 24, 58),
            child: const Center(
              child: SizedBox(
                width: 980,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRIVATE ACTIVITY',
                      style: TextStyle(
                        color: Color(0xFFB8CEC4),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Your Affinity updates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Deal changes, saved-deal updates, professional pitches, and buyer decisions—visible only to the account involved.',
                      style: TextStyle(color: Color(0xFFD8E4DE), height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 980,
              constraints: const BoxConstraints(minHeight: 420),
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 80),
              child: FutureBuilder<List<AffinityNotification>>(
                future: _notifications,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _green),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text('Could not load updates: ${snapshot.error}');
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No private updates yet.',
                        style: TextStyle(color: _muted),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: item.read
                                    ? const Color(0xFFE9E8E3)
                                    : const Color(0xFFDCECE4),
                                child: Icon(
                                  item.read
                                      ? Icons.notifications_none
                                      : Icons.notifications_active_outlined,
                                  color: _green,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.read
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${item.message}\n${DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal())}',
                                  style: const TextStyle(
                                    color: _muted,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_rounded),
                              onTap: () => _open(item),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const MembershipFooter(),
        ],
      ),
    ),
  );
}
