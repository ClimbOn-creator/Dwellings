import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

class SiteContentService {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static final Map<String, String> _values = {};

  static const Map<String, Map<String, String>> sections = {
    'Landing page': {
      'home.eyebrow': 'BUSINESS ACQUISITION, MADE NAVIGABLE',
      'home.title':
          'Don’t just find a business.\nKnow what you’re buying into.',
      'home.intro':
          'Affinity helps aspiring buyers define the right target, prepare to transact, screen real opportunities, and build the professional team needed to close with confidence.',
      'home.goal':
          'A clearer path from “I want to buy a business” to “this is the right business for me.”',
      'home.goal_body':
          'The goal is not more deal flow. It is better judgment: a personal acquisition Blueprint, an honest view of readiness, disciplined screening, and access to specialists when the stakes rise.',
      'home.buyer_title': 'Turn interest into a mandate.',
      'home.buyer_body':
          'Learn the path, define what fits your life and capital, measure your readiness, and screen opportunities against your own rules.',
      'home.member_title': 'Be visible when buyers need you.',
      'home.member_body':
          'Build a credible professional presence and respond privately when an Affinity-reviewed opportunity fits your expertise.',
    },
    'Step 1 · Blueprint': {
      'blueprint.title': 'Acquisition Blueprint',
      'blueprint.subtitle':
          'Define the acquisition you want before a compelling deal changes the rules.',
      'blueprint.q1_title': 'What kind of owner do you want to become?',
      'blueprint.q1_body':
          'Start with the role and structure—not a price. You can revise this as your search becomes clearer.',
      'blueprint.q2_title': 'What would feel like a natural fit?',
      'blueprint.q2_body':
          'Use plain language. A broad answer is useful; “local service businesses” is enough to begin.',
      'blueprint.q3_title': 'Do you know your financial range?',
      'blueprint.q3_body':
          'These figures are optional planning estimates—not a test or lending approval. Leave them blank if you are still learning.',
      'blueprint.q4_title': 'What should protect you from the wrong deal?',
      'blueprint.q4_body':
          'Name the risks you already know you do not want. If nothing comes to mind, uncertainty is a valid answer.',
    },
    'Step 2 · Readiness': {
      'readiness.title': 'Buyer Readiness',
      'readiness.subtitle':
          'Understand what you can execute now and your path to becoming transaction-ready.',
      'readiness.q1_title': 'What capital could be available?',
      'readiness.q1_body':
          'A rough range is enough. Leave every field blank if you have not had this conversation yet.',
      'readiness.q2_title': 'What supports the acquisition?',
      'readiness.q2_body':
          'These answers help frame—not approve—your capacity. “I’m not sure yet” is included on purpose.',
      'readiness.q3_title': 'What is already in motion?',
      'readiness.q3_body':
          'This is a planning checklist, not homework you must finish today. Select only what is genuinely underway.',
    },
    'Step 3 · Deal screen': {
      'screen.title': 'Initial Deal Screen',
      'screen.subtitle':
          'Test whether a specific business fits your Blueprint and whether its cash flow can support you.',
      'screen.privacy':
          'CONFIDENTIAL DATA BOUNDARY · Use summarized figures only. Do not upload tax returns, payroll, customer lists, employee records or confidential seller documents.',
      'screen.form_help':
          'Use only the figures you have. Blank fields remain unknown and become questions for diligence.',
    },
    'Step 4 · Pipeline': {
      'pipeline.title': 'My Deal Pipeline',
      'pipeline.subtitle':
          'Keep every opportunity, decision, deadline, and blocker in one focused acquisition workspace.',
      'pipeline.empty_title': 'Your pipeline starts with one real opportunity.',
      'pipeline.empty_body':
          'Add a deal when you have enough information to name it. You can keep early details private and incomplete.',
    },
    'Member Studio': {
      'studio.eyebrow': 'AFFINITY PROFESSIONAL NETWORK',
      'studio.title': 'Opportunity meets expertise.',
      'studio.intro':
          'A private professional network where verified specialists discover Affinity-reviewed acquisitions, understand the need, and make a concise confidential pitch.',
      'studio.privacy':
          'Members see only an Affinity-written opportunity brief. Buyer names, exact addresses, documents, raw assessments, and contact details remain private until the buyer accepts a pitch.',
      'studio.opportunities_title': 'Reviewed opportunities',
      'studio.professionals_title': 'Verified professionals',
      'studio.professionals_intro':
          'Find the people buyers may need across financing, diligence, legal, tax, insurance, operations, and transition.',
    },
    'Consulting': {
      'consulting.title': 'Founder-led acquisition consulting',
      'consulting.subtitle':
          'A personal, rigorous second set of eyes for the decisions that shape what you buy—and what happens after.',
      'consulting.heading':
          'Acquisition decisions deserve more than a spreadsheet.',
      'consulting.body':
          'Affinity brings personal goals, financial readiness, and deal criteria into one candid decision process. Sessions sharpen a mandate, identify readiness gaps, challenge a live opportunity, or organize the next phase of diligence.',
    },
  };

  static Future<void> initialize() async {
    if (!BackendService.configured) return;
    try {
      final rows = await Supabase.instance.client
          .from('site_content')
          .select('content_key, content_value');
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        _values[row['content_key'] as String] =
            row['content_value'] as String? ?? '';
      }
      revision.value++;
    } catch (_) {
      // Published defaults remain available while the content migration rolls out.
    }
  }

  static String text(String key, String fallback) => _values[key] ?? fallback;

  static Future<bool> canEdit() async {
    if (!BackendService.configured || BackendService.user == null) return false;
    try {
      return await Supabase.instance.client.rpc('is_affinity_content_editor')
              as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> save(String key, String value) async {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in with an Affinity content editor account.');
    }
    _values[key] = value;
    revision.value++;
    await Supabase.instance.client.rpc(
      'save_site_content',
      params: {'target_key': key, 'target_value': value},
    );
  }
}
