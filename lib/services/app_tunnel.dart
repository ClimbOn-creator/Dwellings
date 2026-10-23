import 'package:flutter/foundation.dart';

/// Navigation context, independent of membership permissions and deal access.
/// Returning home clears it; signing in keeps the path the visitor chose.
enum AppTunnel { landing, buyer, seller, member, learning }

class AppTunnelController {
  static final current = ValueNotifier<AppTunnel>(AppTunnel.landing);
  static void select(AppTunnel tunnel) => current.value = tunnel;
  static AppTunnel forModule(String? module) => switch (module) {
    'deal-comparison' ||
    'learning-dashboard' ||
    'learning-seminars' ||
    'learning-pipeline' ||
    'learning-quiz' ||
    'learning-transaction-room' ||
    'acquisition-journey' ||
    'learning-map' => AppTunnel.learning,
    'buyer-pipeline' ||
    'buyer-dashboard' ||
    'buyer-learning' ||
    'deal-rooms' ||
    'business-calculator' ||
    'bulletin-board' ||
    'businesses-for-sale' ||
    'resources' ||
    'transaction-room' ||
    'document-guides' => AppTunnel.buyer,
    'seller-dashboard' ||
    'seller-learning' ||
    'succession-transfer' ||
    'seller-posts' ||
    'seller-transaction-room' => AppTunnel.seller,
    'member-studio' ||
    'member-dashboard' ||
    'member-onboarding' ||
    'professional-onboarding' ||
    'member-pricing' ||
    'member-marketing' => AppTunnel.member,
    _ => AppTunnel.landing,
  };
}
