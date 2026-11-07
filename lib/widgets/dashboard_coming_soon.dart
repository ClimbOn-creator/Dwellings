import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/page_flow.dart';
import 'home_brand_button.dart';

const privateDashboardsAvailable = !kIsWeb;
const dashboardComingSoon = 'Coming soon!';

/// Keep inactive dashboards from creating their workspace state on web.
class DashboardComingSoonState<T extends StatefulWidget> extends State<T> {
  DashboardComingSoonState(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => DashboardComingSoonPage(title: title);
}

class DashboardComingSoonPage extends StatelessWidget {
  const DashboardComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const HomeBrandButton(dark: false)),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(dashboardComingSoon),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => startLearning(context),
            child: const Text('Open Learning dashboard'),
          ),
        ],
      ),
    ),
  );
}
