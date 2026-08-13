import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';
import 'marketplace_service.dart';

enum AccountRole {
  user,
  realtor,
  mortgageBroker,
  lawyer,
  accountant,
  lender,
  businessBroker,
  maLawyer,
  qualityOfEarnings,
  commercialLender,
  taxAdvisor,
  insuranceAdvisor,
  humanResources,
  cybersecurity,
  industryAdvisor,
  wealthManager,
}

extension AccountRoleDetails on AccountRole {
  String get databaseValue => switch (this) {
    AccountRole.user => 'user',
    AccountRole.realtor => 'realtor',
    AccountRole.mortgageBroker => 'mortgage_broker',
    AccountRole.lawyer => 'lawyer',
    AccountRole.accountant => 'accountant',
    AccountRole.lender => 'lender',
    AccountRole.businessBroker => 'business_broker',
    AccountRole.maLawyer => 'ma_lawyer',
    AccountRole.qualityOfEarnings => 'quality_of_earnings',
    AccountRole.commercialLender => 'commercial_lender',
    AccountRole.taxAdvisor => 'tax_advisor',
    AccountRole.insuranceAdvisor => 'insurance_advisor',
    AccountRole.humanResources => 'human_resources',
    AccountRole.cybersecurity => 'cybersecurity',
    AccountRole.industryAdvisor => 'industry_advisor',
    AccountRole.wealthManager => 'wealth_manager',
  };

  String get label => switch (this) {
    AccountRole.user => 'Buyer or investor',
    AccountRole.realtor => 'Realtor',
    AccountRole.mortgageBroker => 'Mortgage broker',
    AccountRole.lawyer => 'Property lawyer',
    AccountRole.accountant => 'Accountant',
    AccountRole.lender => 'Bank or lender',
    AccountRole.businessBroker => 'Business broker',
    AccountRole.maLawyer => 'M&A lawyer',
    AccountRole.qualityOfEarnings => 'QOE professional',
    AccountRole.commercialLender => 'Commercial lender',
    AccountRole.taxAdvisor => 'Tax adviser',
    AccountRole.insuranceAdvisor => 'Insurance adviser',
    AccountRole.humanResources => 'HR specialist',
    AccountRole.cybersecurity => 'Cybersecurity consultant',
    AccountRole.industryAdvisor => 'Industry adviser',
    AccountRole.wealthManager => 'Wealth manager',
  };
}

class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.jobTitle,
    required this.companyName,
    required this.employmentType,
    required this.photoUrl,
    required this.bio,
  });

  final String id;
  final String username;
  final String fullName;
  final String role;
  final String jobTitle;
  final String companyName;
  final String employmentType;
  final String photoUrl;
  final String bio;

  factory AccountProfile.fromJson(Map<String, dynamic> row) => AccountProfile(
    id: row['id'] as String,
    username: row['username'] as String? ?? '',
    fullName:
        row['full_name'] as String? ?? row['display_name'] as String? ?? '',
    role: row['account_role'] as String? ?? 'user',
    jobTitle: row['job_title'] as String? ?? '',
    companyName: row['company_name'] as String? ?? '',
    employmentType: row['employment_type'] as String? ?? '',
    photoUrl: row['profile_photo_url'] as String? ?? '',
    bio: row['bio'] as String? ?? '',
  );
}

class DashboardStats {
  const DashboardStats({
    required this.analysisCount,
    required this.teamCount,
    required this.introductionCount,
    required this.dealRoomCount,
    required this.lastAddress,
    required this.lastRisk,
  });
  final int analysisCount;
  final int teamCount;
  final int introductionCount;
  final int dealRoomCount;
  final String lastAddress;
  final double? lastRisk;
}

class IntroductionRequest {
  const IntroductionRequest({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerCompany,
    required this.status,
    required this.requesterName,
    required this.requesterEmail,
    required this.requesterPhone,
    required this.propertySummary,
    required this.memberMessage,
    required this.createdAt,
    required this.respondedAt,
    required this.nextFollowUpAt,
    required this.providerNotes,
    required this.closedReason,
    required this.preferredContact,
    required this.leadType,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String providerCompany;
  final String status;
  final String requesterName;
  final String requesterEmail;
  final String requesterPhone;
  final String propertySummary;
  final String memberMessage;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? nextFollowUpAt;
  final String providerNotes;
  final String closedReason;
  final String preferredContact;
  final String leadType;

  factory IntroductionRequest.fromJson(Map<String, dynamic> row) {
    final provider = row['provider_profiles'] is Map
        ? Map<String, dynamic>.from(row['provider_profiles'] as Map)
        : <String, dynamic>{};
    return IntroductionRequest(
      id: row['id'] as String,
      providerId: row['provider_id'] as String,
      providerName: provider['display_name'] as String? ?? 'Professional',
      providerCompany: provider['company_name'] as String? ?? '',
      status: row['status'] as String? ?? 'new',
      requesterName: row['requester_name'] as String? ?? '',
      requesterEmail: row['requester_email'] as String? ?? '',
      requesterPhone: row['requester_phone'] as String? ?? '',
      propertySummary: row['property_summary'] as String? ?? '',
      memberMessage: row['member_message'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
      respondedAt: row['responded_at'] == null
          ? null
          : DateTime.tryParse(row['responded_at'] as String),
      nextFollowUpAt: row['next_follow_up_at'] == null
          ? null
          : DateTime.tryParse(row['next_follow_up_at'] as String),
      providerNotes: row['provider_notes'] as String? ?? '',
      closedReason: row['closed_reason'] as String? ?? '',
      preferredContact: row['preferred_contact'] as String? ?? 'email',
      leadType: row['lead_type'] as String? ?? 'general',
    );
  }
}

class ProfessionalWorkspaceStats {
  const ProfessionalWorkspaceStats({
    required this.membershipTier,
    required this.teamSaves,
    required this.introductions,
    required this.dealRooms,
    required this.onboardingStatus,
    required this.verified,
    required this.acceptingLeads,
    required this.profileCompleteness,
  });
  final String membershipTier;
  final int teamSaves;
  final int introductions;
  final int dealRooms;
  final String onboardingStatus;
  final bool verified;
  final bool acceptingLeads;
  final int profileCompleteness;
}

class AccountService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const _introductionSelect =
      'id, provider_id, status, requester_name, requester_email, requester_phone, '
      'property_summary, member_message, created_at, responded_at, '
      'next_follow_up_at, provider_notes, closed_reason, preferred_contact, lead_type, '
      'provider_profiles(id, display_name, company_name, owner_user_id)';

  static Future<bool> usernameAvailable(String username) async {
    final value = await _client.rpc(
      'username_available',
      params: {'candidate': username.trim()},
    );
    return value == true;
  }

  static Future<AuthResponse> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required AccountRole role,
    String? jobTitle,
    String? companyName,
    String? employmentType,
  }) async {
    if (!await usernameAvailable(username)) {
      throw const AuthException(
        'That username is already taken or is not valid.',
      );
    }
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: Uri.base.origin,
      data: {
        'full_name': fullName.trim(),
        'username': username.trim(),
        'account_role': role.databaseValue,
        'job_title': jobTitle?.trim() ?? '',
        'company_name': companyName?.trim() ?? '',
        'employment_type': employmentType ?? '',
      },
    );
  }

  static Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);

  static Future<AccountProfile?> loadProfile() async {
    final user = BackendService.user;
    if (user == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return row == null ? null : AccountProfile.fromJson(row);
  }

  static Future<void> updateProfile({
    required String fullName,
    required String jobTitle,
    required String companyName,
    required String employmentType,
    required String bio,
  }) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in required.');
    await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'display_name': fullName.trim(),
          'job_title': jobTitle.trim(),
          'company_name': companyName.trim(),
          'employment_type': employmentType.isEmpty ? null : employmentType,
          'bio': bio.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  static Future<String> uploadProfilePhoto(
    Uint8List bytes,
    String extension,
  ) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in required.');
    final safeExtension =
        ['jpg', 'jpeg', 'png', 'webp'].contains(extension.toLowerCase())
        ? extension.toLowerCase()
        : 'jpg';
    final path = '${user.id}/profile.$safeExtension';
    await _client.storage
        .from('profile-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('profile-photos').getPublicUrl(path);
    await _client
        .from('profiles')
        .update({'profile_photo_url': url})
        .eq('id', user.id);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<DashboardStats> loadStats() async {
    final user = BackendService.user;
    if (user == null) {
      return const DashboardStats(
        analysisCount: 0,
        teamCount: 0,
        introductionCount: 0,
        dealRoomCount: 0,
        lastAddress: '',
        lastRisk: null,
      );
    }
    final analyses = await _client
        .from('property_analyses')
        .select('address_label, model_output, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);
    final team = await _client
        .from('user_team_members')
        .select('provider_id')
        .eq('user_id', user.id);
    final introductions = await _client
        .from('lead_requests')
        .select('id')
        .eq('user_id', user.id);
    final dealRooms = await _client.from('deal_rooms').select('id');
    final latest = analyses.isEmpty
        ? null
        : Map<String, dynamic>.from(analyses.first);
    final output = latest?['model_output'] is Map
        ? Map<String, dynamic>.from(latest!['model_output'] as Map)
        : <String, dynamic>{};
    return DashboardStats(
      analysisCount: analyses.length,
      teamCount: team.length,
      introductionCount: introductions.length,
      dealRoomCount: dealRooms.length,
      lastAddress: latest?['address_label'] as String? ?? '',
      lastRisk: (output['risk'] as num?)?.toDouble(),
    );
  }

  static Future<List<MarketplaceProvider>> loadTeam() async {
    final user = BackendService.user;
    if (user == null) return [];
    final rows = await _client
        .from('user_team_members')
        .select(
          'provider_profiles(id, provider_type, display_name, company_name, description, phone, email, website_url, '
          'license_number, license_region, accepting_leads, membership_tier, verified, years_experience, review_score, review_count, job_title, '
          'is_example, photo_index, logo_object_key, '
          'provider_regions(service_regions(city, region, country_code)), '
          'sponsored_placements(disclosure_label, active, starts_at, ends_at), '
          'lender_rates(interest_rate, mortgage_type, verified_at, effective_at, expires_at))',
        )
        .eq('user_id', user.id)
        .order('created_at');
    final providers = rows
        .map((row) => row['provider_profiles'])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    return MarketplaceService.providersFromRows(providers);
  }

  static Future<void> removeTeamMember(String providerId) async {
    final user = BackendService.user;
    if (user == null) return;
    await _client
        .from('user_team_members')
        .delete()
        .eq('user_id', user.id)
        .eq('provider_id', providerId);
  }

  static Future<void> requestIntroduction({
    required MarketplaceProvider provider,
    required String propertySummary,
    String? phone,
    String preferredContact = 'email',
    String leadType = 'general',
  }) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to request an introduction.');
    if (provider.isExample) return;
    final profile = await loadProfile();
    await _client.from('lead_requests').insert({
      'user_id': user.id,
      'provider_id': provider.id,
      'requester_name': profile?.fullName.isNotEmpty == true
          ? profile!.fullName
          : user.email?.split('@').first ?? 'DwellingsIQ member',
      'requester_email': user.email ?? '',
      'requester_phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'property_summary': propertySummary.trim(),
      'preferred_contact': preferredContact,
      'lead_type': leadType,
      'consent_to_contact': true,
    });
  }

  static Future<List<IntroductionRequest>> loadOutgoingIntroductions() async {
    final user = BackendService.user;
    if (user == null) return [];
    final rows = await _client
        .from('lead_requests')
        .select(_introductionSelect)
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return rows
        .map(
          (row) => IntroductionRequest.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  static Future<List<IntroductionRequest>> loadIncomingIntroductions() async {
    final user = BackendService.user;
    if (user == null) return [];
    final rows = await _client
        .from('lead_requests')
        .select(
          'id, provider_id, status, requester_name, requester_email, requester_phone, '
          'property_summary, member_message, created_at, responded_at, '
          'next_follow_up_at, provider_notes, closed_reason, preferred_contact, lead_type, '
          'provider_profiles!inner(id, display_name, company_name, owner_user_id)',
        )
        .eq('provider_profiles.owner_user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return rows
        .map(
          (row) => IntroductionRequest.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  static Future<void> respondToIntroduction({
    required String introductionId,
    required String status,
    String message = '',
    DateTime? followUpAt,
    String privateNotes = '',
    String closedReason = '',
  }) async {
    await _client.rpc(
      'respond_to_introduction',
      params: {
        'introduction_id': introductionId,
        'response_status': status,
        'response_message': message,
        'follow_up_at': followUpAt?.toIso8601String(),
        'private_notes': privateNotes,
        'loss_reason': closedReason,
      },
    );
  }

  static Future<ProfessionalWorkspaceStats?> loadProfessionalStats() async {
    final user = BackendService.user;
    if (user == null) return null;
    final providers = await _client
        .from('provider_profiles')
        .select(
          'id, membership_tier, onboarding_status, verified, accepting_leads, '
          'display_name, company_name, description, phone, email, license_number, specialties, service_markets',
        )
        .eq('owner_user_id', user.id);
    if (providers.isEmpty) return null;
    final ids = providers.map((row) => row['id'] as String).toList();
    final values = await Future.wait([
      _client
          .from('user_team_members')
          .select('provider_id')
          .inFilter('provider_id', ids),
      _client
          .from('lead_requests')
          .select('provider_id')
          .inFilter('provider_id', ids),
      _client
          .from('deal_room_members')
          .select('provider_id')
          .inFilter('provider_id', ids)
          .neq('status', 'removed'),
    ]);
    final provider = Map<String, dynamic>.from(providers.first);
    final requiredValues = [
      provider['display_name'],
      provider['company_name'],
      provider['description'],
      provider['phone'],
      provider['email'],
    ];
    final completed =
        requiredValues.where((value) => '$value'.trim().isNotEmpty).length +
        ((provider['specialties'] as List?)?.isNotEmpty == true ? 1 : 0) +
        ((provider['service_markets'] as List?)?.isNotEmpty == true ? 1 : 0);
    return ProfessionalWorkspaceStats(
      membershipTier: providers.first['membership_tier'] as String? ?? 'free',
      teamSaves: (values[0] as List).length,
      introductions: (values[1] as List).length,
      dealRooms: (values[2] as List).length,
      onboardingStatus: provider['onboarding_status'] as String? ?? 'draft',
      verified: provider['verified'] as bool? ?? false,
      acceptingLeads: provider['accepting_leads'] as bool? ?? false,
      profileCompleteness: ((completed / 7) * 100).round(),
    );
  }

  static Future<void> saveDraft(Map<String, dynamic> draft) async {
    final user = BackendService.user;
    if (user == null) return;
    await _client.from('property_drafts').upsert({
      'user_id': user.id,
      'draft_data': draft,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> loadDraft() async {
    final user = BackendService.user;
    if (user == null) return null;
    final row = await _client
        .from('property_drafts')
        .select('draft_data')
        .eq('user_id', user.id)
        .maybeSingle();
    return row?['draft_data'] is Map
        ? Map<String, dynamic>.from(row!['draft_data'] as Map)
        : null;
  }
}
