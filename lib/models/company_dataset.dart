import '../services/company_data_service.dart';

class DataPoint {
  const DataPoint(this.day, this.value);
  final String day;
  final double value;
}

class CompanyDataset {
  const CompanyDataset(
    this.id,
    this.title,
    this.group,
    this.description, {
    this.breakdown,
    this.source,
    this.dateField,
    this.bytes = false,
  });
  final String id, title, group, description;
  final String? breakdown, source, dateField;
  final bool bytes;
}

const companyDatasets = <CompanyDataset>[
  CompanyDataset(
    'accounts',
    'Registered accounts',
    'People',
    'Accounts registered with Affinity. Registration does not prove an active or returning user.',
    source: 'auth.users',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'profiles',
    'Saved profiles',
    'People',
    'Current saved account profiles. Location is a preference, not a verified home address.',
    breakdown: 'roles',
    source: 'profiles',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'provider_profiles',
    'Professional members',
    'Network',
    'Real professional profiles, excluding examples. Membership status is not a record of payment.',
    breakdown: 'professions',
    source: 'provider_profiles',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'membership_applications',
    'Member applications',
    'Network',
    'Saved applications, including pending or declined applications. An application is not a paid subscription.',
    source: 'membership_applications',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'user_team_members',
    'Team selections',
    'Network',
    'Current links to real professionals. Examples are excluded. A selection does not confirm a hire, and removed links are no longer counted.',
    breakdown: 'teams',
    source: 'user_team_members',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'lead_requests',
    'Introduction requests',
    'Network',
    'Saved requests for contact or introductions. A request does not prove a professional engagement.',
    source: 'lead_requests',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'deal_rooms',
    'Deal pipeline',
    'Business',
    'Current deal rooms, grouped by saved stage. Stages are self-reported, not independently verified closings.',
    breakdown: 'pipeline',
    source: 'deal_rooms',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'business_assessments',
    'Business assessments',
    'Business',
    'Saved business calculations. Counts do not expose business names, financial inputs or results.',
    source: 'business_assessments',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'property_analyses',
    'Property analyses',
    'Business',
    'Saved property calculations. Device-only drafts are not included.',
    source: 'property_analyses',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'deal_room_members',
    'Deal-room invitations',
    'Business',
    'Saved deal-room memberships and invitations, across all statuses.',
    source: 'deal_room_members',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'deal_room_tasks',
    'Pipeline tasks',
    'Business',
    'Tasks saved in deal rooms, including completed tasks. The trend uses task creation, not completion.',
    source: 'deal_room_tasks',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'deal_room_documents',
    'Deal documents',
    'Business',
    'Current documents, excluding soft-deleted files. Only aggregate counts appear here.',
    source: 'deal_room_documents',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'deal_room_document_events',
    'Document activity',
    'Business',
    'Recorded document activity events. These are events, not unique documents or people.',
    source: 'deal_room_document_events',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'member_deal_opportunities',
    'Member opportunities',
    'Business',
    'Saved opportunities, using their submission date. Not all opportunities have been published.',
    source: 'member_deal_opportunities',
    dateField: 'submitted_at',
  ),
  CompanyDataset(
    'member_deal_pitches',
    'Member pitches',
    'Business',
    'Saved professional pitches. A pitch is not an accepted engagement.',
    source: 'member_deal_pitches',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'member_deal_referrals',
    'Member referrals',
    'Network',
    'Saved referrals across all statuses. No referral message content is returned.',
    source: 'member_deal_referrals',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'member_saved_deals',
    'Saved opportunities',
    'Business',
    'Current saved-deal links. Removing a save removes it from this report.',
    source: 'member_saved_deals',
    dateField: 'saved_at',
  ),
  CompanyDataset(
    'member_conversations',
    'Conversations',
    'Network',
    'Saved conversation records. Private message text is not part of this dashboard.',
    source: 'member_conversations',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'member_messages',
    'Messages sent',
    'Network',
    'Retained message records. Counts include no message text or participant identities.',
    source: 'member_messages',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'learning_posts',
    'Learning posts',
    'Learning',
    'Saved learning posts across statuses. Device-only example posts are excluded.',
    source: 'learning_posts',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'learning_comments',
    'Learning comments',
    'Learning',
    'Retained comments, excluding removed comments and device-only examples.',
    source: 'learning_comments',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'learning_reactions',
    'Learning reactions',
    'Learning',
    'Current reaction and bookmark records. Removed reactions are no longer counted.',
    source: 'learning_reactions',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'learning_seminars',
    'Map & seminar events',
    'Learning',
    'Events saved by publishers. The trend shows when events were created, not when they take place.',
    source: 'learning_seminars',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'learning_rsvps',
    'Event registrations',
    'Learning',
    'Current RSVP records. Registrations do not verify attendance.',
    source: 'learning_rsvps',
    dateField: 'created_at',
  ),
  CompanyDataset(
    'learning_progress',
    'Lessons completed',
    'Learning',
    'Retained lesson-completion records. One person can complete several lessons.',
    source: 'learning_progress',
    dateField: 'completed_at',
  ),
  CompanyDataset(
    'learning_media',
    'Post attachments',
    'Learning',
    'Current learning-media metadata. Creation timestamps are not stored for these records, so only a snapshot is available.',
    source: 'learning_media',
  ),
  CompanyDataset(
    'learning_event_images',
    'Event images',
    'Learning',
    'Current event-image metadata. Creation timestamps are not stored for these records, so only a snapshot is available.',
    source: 'learning_event_images',
  ),
  CompanyDataset(
    'affinity_usage_daily',
    'App-area visits',
    'Usage',
    'Optional anonymous signed-in navigation counts. Not unique visitors. Owners and walkthrough previews are excluded; historical browsing cannot be reconstructed.',
    breakdown: 'feature_visits',
    source: 'affinity_usage_daily',
    dateField: 'day',
  ),
  CompanyDataset(
    'database_bytes',
    'Database volume',
    'Storage',
    'Current size of the 27 tracked tables and their indexes. It is not the size of every hosting bucket or backup. Historical storage measurements are not recorded.',
    bytes: true,
  ),
  CompanyDataset(
    'uploaded_bytes',
    'Uploaded file volume',
    'Storage',
    'Current byte sizes in deal-document and learning-media metadata. This does not cover all storage buckets. Historical sizes are not recorded.',
    bytes: true,
  ),
  CompanyDataset(
    'account_roles',
    'Account roles',
    'People',
    'Current saved account-role distribution. Historical role changes are not recorded.',
    breakdown: 'roles',
    source: 'profiles',
  ),
  CompanyDataset(
    'profile_locations',
    'Saved locations',
    'People',
    'Current profile city/province preferences, not verified residence. Missing locations are omitted. Historical location changes are not recorded.',
    breakdown: 'locations',
    source: 'profiles',
  ),
  CompanyDataset(
    'member_professions',
    'Member professions',
    'Network',
    'Current profession distribution across real professional profiles. Unknown values are labelled Not provided. Historical profession changes are not recorded.',
    breakdown: 'professions',
    source: 'provider_profiles',
  ),
  CompanyDataset(
    'member_status',
    'Membership status',
    'Network',
    'Current status of real professional profiles. This is not collected subscription revenue and does not reconstruct past statuses.',
    breakdown: 'member_status',
    source: 'provider_profiles',
  ),
  CompanyDataset(
    'pipeline_stages',
    'Pipeline stages',
    'Business',
    'Current saved stages across deal rooms. Historical stage movements and independently verified closings are unavailable.',
    breakdown: 'pipeline',
    source: 'deal_rooms',
  ),
];

class DatasetValues {
  DatasetValues(this.dataset, this.report);
  final CompanyDataset dataset;
  final CompanyDataReport report;
  Map<String, dynamic> get history {
    final histories = report.data['histories'];
    if (histories is! Map || histories[dataset.id] is! Map) return {};
    return Map<String, dynamic>.from(histories[dataset.id] as Map);
  }

  List<DataPoint> get daily => (history['series'] as List? ?? [])
      .map((r) => DataPoint(r['day'] as String, (r['count'] as num).toDouble()))
      .toList();
  bool get hasHistory => history.isNotEmpty;
  double get current {
    final facetTotal = switch (dataset.id) {
      'account_roles' => 'Saved profiles',
      'profile_locations' => 'Profiles with a saved location',
      'member_professions' || 'member_status' => 'Professional profiles',
      'pipeline_stages' => 'Deal rooms',
      _ => null,
    };
    if (facetTotal != null)
      return (report.totals[facetTotal] as num? ?? 0).toDouble();

    if (dataset.id == 'database_bytes') {
      return report
          .rows('inventory')
          .fold<double>(0, (v, r) => v + (r['bytes'] as num).toDouble());
    }
    if (dataset.id == 'uploaded_bytes') {
      return report.number('uploaded_file_bytes').toDouble();
    }
    if (history['current_total'] is num) {
      return (history['current_total'] as num).toDouble();
    }
    final match = report
        .rows('inventory')
        .where((r) => r['label'] == dataset.id)
        .firstOrNull;
    if (match != null) return (match['count'] as num).toDouble();
    return dataset.id == 'accounts'
        ? (report.totals['Registered accounts'] as num? ?? 0).toDouble()
        : 0;
  }

  double get period => (history['period_total'] as num? ?? 0).toDouble();
  double get previous => (history['previous_total'] as num? ?? 0).toDouble();
  double? get changePercent => !hasHistory || previous == 0
      ? null
      : (period - previous) / previous * 100;
  List<Map<String, dynamic>> get breakdown =>
      dataset.breakdown == null ? [] : report.rows(dataset.breakdown!);
  List<String> get breakdownKeys => switch (dataset.id) {
    'profiles' => ['roles', 'locations'],
    'provider_profiles' => ['professions', 'member_status'],
    _ => dataset.breakdown == null ? [] : [dataset.breakdown!],
  };

  /// Sum aligned UTC days into readable buckets; never interpolate missing history.
  List<DataPoint> get chartPoints {
    final points = daily;
    if (points.length <= 31) return points;
    final sums = <String, double>{};
    for (var i = 0; i < points.length; i++) {
      final key = points.length <= 90
          ? points[(i ~/ 7) * 7].day
          : '${points[i].day.substring(0, 7)}-01';
      sums[key] = (sums[key] ?? 0) + points[i].value;
    }
    return sums.entries.map((e) => DataPoint(e.key, e.value)).toList();
  }
}
