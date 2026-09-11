import '../widgets/site_text.dart';
import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/membership_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/membership_footer.dart';
import 'auth_page.dart';

const _green = Color(0xFF053827);
const _muted = Color(0xFF68635D);

class ProfessionalOnboardingPage extends StatefulWidget {
  const ProfessionalOnboardingPage({super.key});

  @override
  State<ProfessionalOnboardingPage> createState() =>
      _ProfessionalOnboardingPageState();
}

class _ProfessionalOnboardingPageState
    extends State<ProfessionalOnboardingPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _role = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _license = TextEditingController();
  final _specialties = TextEditingController();
  final _regions = TextEditingController(text: 'British Columbia');
  MemberType _type = MemberType.commercialLender;
  bool _attested = false;
  bool _saving = false;
  bool _sent = false;

  static final _types = MemberType.values
      .where((value) => value.isProfessional)
      .toList();

  @override
  void initState() {
    super.initState();
    _email.text = BackendService.user?.email ?? '';
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _company,
      _role,
      _email,
      _phone,
      _bio,
      _license,
      _specialties,
      _regions,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || !_attested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SiteText(
            contentKey: 'copy.professional_onboarding_page.m1',
            literal: true,
            'Complete the required fields and professional attestation.',
          ),
        ),
      );
      return;
    }
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() => _saving = true);
    try {
      await MembershipService.submit({
        'applicant_type': _type.databaseValue,
        'full_name': _name.text.trim(),
        'company_name': _company.text.trim(),
        'job_title': _role.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'notes': _bio.text.trim(),
        'license_number': _license.text.trim(),
        'license_region': 'Canada',
        'specialties': _split(_specialties.text),
        'service_markets': _split(_regions.text),
        'requested_tier': 'professional',
        'consent_to_contact': true,
        'professional_attestation': true,
      });
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              templateValues: {'value1': '${error}'},
              contentKey: 'copy.professional_onboarding_page.m2',
              literal: false,
              "Could not submit: {{value1}}",
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _split(String value) => value
      .split(RegExp(r'[,\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F3EF),
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
            padding: const EdgeInsets.fromLTRB(24, 62, 24, 60),
            child: const Center(
              child: SizedBox(
                width: 1040,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SiteText(
                      contentKey: 'copy.professional_onboarding_page.m3',
                      literal: true,
                      'FOUNDING PROFESSIONAL NETWORK',
                      style: TextStyle(
                        color: Color(0xFFB8CEC4),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 14),
                    SiteText(
                      contentKey: 'copy.professional_onboarding_page.m4',
                      literal: true,
                      'Put your expertise where buyers need it.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 720,
                      child: SiteText(
                        contentKey: 'copy.professional_onboarding_page.m5',
                        literal: true,
                        'Build a verified professional profile, choose the opportunities you want to see, and pitch anonymous buyers without exposing their identity.',
                        style: TextStyle(
                          color: Color(0xFFD8E4DE),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 900,
              padding: const EdgeInsets.fromLTRB(22, 38, 22, 80),
              child: _sent ? _success() : _application(),
            ),
          ),
          const MembershipFooter(),
        ],
      ),
    ),
  );

  Widget _success() => Container(
    padding: const EdgeInsets.all(42),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      children: [
        Icon(Icons.verified_outlined, size: 42, color: _green),
        SizedBox(height: 18),
        SiteText(
          contentKey: 'copy.professional_onboarding_page.m6',
          literal: true,
          'Application received',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 12),
        SiteText(
          contentKey: 'copy.professional_onboarding_page.m7',
          literal: true,
          'Affinity will verify your profile before it appears in the directory or can pitch opportunities. We will notify you when access changes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.5),
        ),
      ],
    ),
  );

  Widget _application() => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SiteText(
          contentKey: 'copy.professional_onboarding_page.1',
          literal: true,
          '01 · Professional identity',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        _pair(
          TextFormField(
            controller: _name,
            validator: _required,
            decoration: const InputDecoration(
              label: SiteText(
                'Full name',
                contentKey: 'copy.professional_onboarding_page.field1',
                literal: true,
              ),
            ),
          ),
          TextFormField(
            controller: _company,
            validator: _required,
            decoration: const InputDecoration(
              label: SiteText(
                'Company',
                contentKey: 'copy.professional_onboarding_page.field2',
                literal: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _pair(
          TextFormField(
            controller: _role,
            validator: _required,
            decoration: const InputDecoration(
              label: SiteText(
                'Role / title',
                contentKey: 'copy.professional_onboarding_page.field3',
                literal: true,
              ),
            ),
          ),
          DropdownButtonFormField<MemberType>(
            initialValue: _type,
            decoration: const InputDecoration(
              label: SiteText(
                'Professional category',
                contentKey: 'copy.professional_onboarding_page.field4',
                literal: true,
              ),
            ),
            items: [
              for (final type in _types)
                DropdownMenuItem(
                  value: type,
                  child: SiteText(
                    contentKey: 'copy.professional_onboarding_page.m8',
                    literal: false,
                    type.label,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
        ),
        const SizedBox(height: 36),
        const SiteText(
          contentKey: 'copy.professional_onboarding_page.2',
          literal: true,
          '02 · Expertise and reach',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _bio,
          validator: _required,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            label: SiteText(
              'Short professional introduction',
              contentKey: 'copy.professional_onboarding_page.field5',
              literal: true,
            ),
            hint: SiteText(
              'What do you do, who do you help, and what makes your approach useful in an acquisition?',
              contentKey: 'copy.professional_onboarding_page.field6',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _pair(
          TextFormField(
            controller: _specialties,
            validator: _required,
            maxLines: 2,
            decoration: const InputDecoration(
              label: SiteText(
                'Specialties',
                contentKey: 'copy.professional_onboarding_page.field7',
                literal: true,
              ),
              hint: SiteText(
                'Commercial lending, SBA, acquisition finance',
                contentKey: 'copy.professional_onboarding_page.field8',
                literal: true,
              ),
            ),
          ),
          TextFormField(
            controller: _regions,
            validator: _required,
            maxLines: 2,
            decoration: const InputDecoration(
              label: SiteText(
                'Service regions',
                contentKey: 'copy.professional_onboarding_page.field9',
                literal: true,
              ),
              hint: SiteText(
                'British Columbia, Alberta',
                contentKey: 'copy.professional_onboarding_page.field10',
                literal: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _license,
          decoration: const InputDecoration(
            label: SiteText(
              'Licence / designation (if applicable)',
              contentKey: 'copy.professional_onboarding_page.field11',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 36),
        const SiteText(
          contentKey: 'copy.professional_onboarding_page.3',
          literal: true,
          '03 · Contact and verification',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        _pair(
          TextFormField(
            controller: _email,
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Valid email required',
            decoration: const InputDecoration(
              label: SiteText(
                'Professional email',
                contentKey: 'copy.professional_onboarding_page.field12',
                literal: true,
              ),
            ),
          ),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(
              label: SiteText(
                'Phone',
                contentKey: 'copy.professional_onboarding_page.field13',
                literal: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _attested,
          onChanged: (value) => setState(() => _attested = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: const SiteText(
            contentKey: 'copy.professional_onboarding_page.4',
            literal: true,
            'I confirm this information is accurate and Affinity may verify my professional standing.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          color: const Color(0xFFE4EBE7),
          child: const SiteText(
            contentKey: 'copy.professional_onboarding_page.5',
            literal: true,
            'FOUNDING MEMBER BETA · No payment today. Your professional tier is activated only after Affinity verifies your profile. Future paid billing will require your separate approval.',
            style: TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          ),
          child: SiteText(
            contentKey: 'copy.professional_onboarding_page.m9',
            literal: false,
            _saving ? 'SUBMITTING…' : 'SUBMIT FOR VERIFICATION',
          ),
        ),
      ],
    ),
  );

  Widget _pair(Widget left, Widget right) => LayoutBuilder(
    builder: (context, box) => box.maxWidth < 650
        ? Column(children: [left, const SizedBox(height: 14), right])
        : Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 14),
              Expanded(child: right),
            ],
          ),
  );
}
