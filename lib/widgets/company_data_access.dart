import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/company_data_service.dart';
import '../services/usage_analytics_service.dart';

class CompanyDataAccess extends StatefulWidget {
  const CompanyDataAccess({super.key, required this.builder});
  final Widget Function(BuildContext, bool) builder;
  @override
  State<CompanyDataAccess> createState() => _CompanyDataAccessState();
}

class _CompanyDataAccessState extends State<CompanyDataAccess> {
  bool _allowed = false;
  int _generation = 0;
  StreamSubscription<dynamic>? _auth;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _check();
    _auth = BackendService.authChanges?.listen((_) {
      setState(() => _allowed = false);
      _check();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check());
  }

  Future<void> _check() async {
    final generation = ++_generation;
    final user = BackendService.user?.id;
    final allowed = await CompanyDataService.isOwner();
    if (mounted &&
        generation == _generation &&
        user == BackendService.user?.id) {
      setState(() => _allowed = allowed);
    }
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _allowed);
}

Future<void> showUsagePrivacy(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Optional usage measurement'),
    content: const SingleChildScrollView(
      child: Text(
        'Help improve Pact by sharing anonymous daily counts of the app areas you open while signed in. No names, IP addresses, full URLs, form answers, messages or documents are included. Your choice is saved for this account on this browser. You can change it here any time. Turning this off stops future measurement; existing anonymous totals cannot be linked back to you. Saved account and business records are separate.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () async {
          await UsageAnalyticsService.choose(false);
          if (context.mounted) Navigator.pop(context);
        },
        child: const Text('No thanks'),
      ),
      FilledButton(
        onPressed: () async {
          await UsageAnalyticsService.choose(true);
          if (context.mounted) Navigator.pop(context);
        },
        child: const Text('Allow usage counts'),
      ),
    ],
  ),
);

class UsagePrivacyHost extends StatelessWidget {
  const UsagePrivacyHost({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(child: child),
      ValueListenableBuilder<bool?>(
        valueListenable: UsageAnalyticsService.consent,
        builder: (context, value, _) =>
            value != null || BackendService.user == null
            ? const SizedBox.shrink()
            : Positioned(
                left: 12,
                right: 12,
                bottom: 100 + MediaQuery.viewPaddingOf(context).bottom,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Help improve Pact?',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Allow anonymous daily counts of the app areas you open while signed in? No names, IPs, form answers or private content. Change this any time on the Privacy page.',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      UsageAnalyticsService.choose(false),
                                  child: const Text('No thanks'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      UsageAnalyticsService.choose(true),
                                  child: const Text('Allow usage counts'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    ],
  );
}
