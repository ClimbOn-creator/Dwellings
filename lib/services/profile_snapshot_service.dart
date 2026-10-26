import 'account_service.dart';
import 'backend_service.dart';
import 'marketplace_service.dart';
import 'workspace_role_service.dart';

class PactProfileSnapshot {
  const PactProfileSnapshot({
    this.account,
    this.professional,
    this.reviews = const [],
    this.member = false,
    this.warning,
  });
  final AccountProfile? account;
  final MarketplaceProvider? professional;
  final List<ProviderReview> reviews;
  final bool member;
  final String? warning;
}

class ProfileSnapshotService {
  static Future<PactProfileSnapshot> load() async {
    if (BackendService.user == null) return const PactProfileSnapshot();
    final warnings = <String>[];
    Future<T?> read<T>(
      String name,
      Future<T?> Function() action, {
      int seconds = 8,
    }) async {
      try {
        return await action().timeout(Duration(seconds: seconds));
      } catch (_) {
        warnings.add(name);
        return null;
      }
    }

    final values = await Future.wait<Object?>([
      read<AccountProfile>('Account', AccountService.loadProfile),
      read<WorkspaceRole>('Workspace', () => WorkspaceRoleService().load()),
      read<MarketplaceProvider>(
        'Professional details',
        () => MarketplaceService.loadMyProfessionalProfile(strict: true),
      ),
    ]);
    final account = values[0] as AccountProfile?;
    final professional = values[2] as MarketplaceProvider?;
    final reviews = professional == null
        ? <ProviderReview>[]
        : await read<List<ProviderReview>>(
                'Reviews',
                () => MarketplaceService.loadReviews(professional.id),
                seconds: 3,
              ) ??
              <ProviderReview>[];
    return PactProfileSnapshot(
      account: account,
      professional: professional,
      member: values[1] == WorkspaceRole.member,
      reviews: reviews,
      warning: warnings.isEmpty
          ? null
          : '${warnings.join(', ')} could not refresh. Your last loaded profile is still available.',
    );
  }
}
