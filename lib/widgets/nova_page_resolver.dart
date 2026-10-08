import 'package:flutter/widgets.dart';

String novaGuidePageFor(BuildContext context) {
  String type = 'Page';
  context.visitAncestorElements((element) {
    final name = element.widget.runtimeType.toString();
    if (name.endsWith('Page') || name.endsWith('Screen')) {
      type = name;
      return false;
    }
    return true;
  });
  return const {
        'AcquisitionSupportPage': 'landing',
        'AcquisitionBlueprintPage': 'blueprint',
        'BuyerReadinessPage': 'readiness',
        'BuyerResourcesPage': 'resources',
        'TransactionLearningPage': 'learning',
        'PersonalizedConsultingPage': 'consulting',
        'DealComparisonPage': 'comparison',
        'BusinessSaleBulletinPage': 'listings',
        'ProfilePage': 'profile',
        'TransactionRoomsPage': 'transaction-rooms',
        'MemberProfilePage': 'member-profile',
        'AuthPage': 'auth',
        'BecomeMemberPage': 'membership',
        'ContentStudioPage': 'content',
        'GuideWorkspacePage': 'learning',
        'MemberStudioPage': 'member/home',
      }[type] ??
      'page:$type';
}
