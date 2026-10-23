import 'package:flutter/material.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/pact_mobile_surface.dart';
import '../widgets/transaction_room_panel.dart';

/// The same document workspace used inside Learning, with its own header when
/// opened through an existing Transaction Room or document-guides link.
class TransactionLearningPage extends StatelessWidget {
  const TransactionLearningPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F5F0),
      foregroundColor: learningInk,
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 40, dark: false),
      actions: const [
        AppNavigationMenu(guidePage: 'document-guides', dark: false),
      ],
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: pactSurfaceGradient),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: TransactionRoomPanel(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
