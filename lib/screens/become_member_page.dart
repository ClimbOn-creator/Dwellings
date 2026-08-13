import 'package:flutter/material.dart';

import '../services/marketplace_service.dart';
import '../services/membership_service.dart';
import '../services/backend_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/auth_button.dart';
import '../widgets/site_footer.dart';
import 'auth_page.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);
const _lilac = Color(0xFFBCAEFF);

class BecomeMemberPage extends StatefulWidget {
  const BecomeMemberPage({
    super.key,
    required this.onHome,
    required this.onAbout,
    required this.onTeam,
  });

  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onTeam;

  @override
  State<BecomeMemberPage> createState() => _BecomeMemberPageState();
}

class _BecomeMemberPageState extends State<BecomeMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _license = TextEditingController();
  final _markets = TextEditingController();
  final _city = TextEditingController();
  final _notes = TextEditingController();
  MemberType _type = MemberType.homebuyer;
  String _province = 'BC';
  String _timeline = 'Within 6 months';
  final Set<String> _specialties = {};
  final Set<String> _propertyTypes = {'Residential'};
  bool _financing = false;
  bool _sponsorship = false;
  bool _consent = false;
  bool _professionalAttestation = false;
  bool _submitting = false;
  bool _complete = false;
  String _requestedTier = 'free';

  static const _professionalSpecialties = [
    'Residential',
    'Commercial',
    'First-time buyers',
    'Investment property',
    'Development',
    'Construction',
    'Luxury',
    'Rural & land',
    'Business acquisitions',
    'Quality of earnings',
    'Transaction tax',
    'Employment & HR',
    'Cybersecurity diligence',
    'Business-owner wealth',
  ];
  static const _buyerPropertyTypes = [
    'Residential',
    'Condo',
    'Multi-family',
    'Commercial',
    'Land',
    'Development',
  ];
  static const _businessBuyerTypes = [
    'Professional services',
    'Trades & construction',
    'Retail & hospitality',
    'Manufacturing',
    'Technology',
    'Healthcare',
    'Distribution',
    'Open to opportunities',
  ];

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _company,
      _license,
      _markets,
      _city,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please consent to being contacted.')),
      );
      return;
    }
    if (_type.isProfessional && !_professionalAttestation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm your professional information.'),
        ),
      );
      return;
    }
    if (_type.isProfessional && BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() => _submitting = true);
    try {
      await MembershipService.submit({
        'applicant_type': _type.databaseValue,
        'full_name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'company_name': _type.isProfessional ? _company.text.trim() : null,
        'license_number': _type.isProfessional ? _license.text.trim() : null,
        'license_region': _type.isProfessional ? _province : null,
        'specialties': _specialties.toList(),
        'service_markets': _type.isProfessional
            ? _markets.text
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList()
            : <String>[],
        'looking_city': _type.isProfessional ? null : _city.text.trim(),
        'looking_province': _type.isProfessional ? null : _province,
        'property_types': _propertyTypes.toList(),
        'purchase_timeline': _type.isProfessional ? null : _timeline,
        'financing_help': !_type.isProfessional && _financing,
        'sponsorship_interest': _type.isProfessional && _sponsorship,
        'requested_tier': _type.isProfessional ? _requestedTier : 'free',
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'consent_to_contact': true,
        'professional_attestation':
            _type.isProfessional && _professionalAttestation,
      });
      if (mounted) setState(() => _complete = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not submit: $error')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(child: _complete ? _success() : _form()),
        SliverToBoxAdapter(
          child: SiteFooter(
            onHome: widget.onHome,
            onAbout: widget.onAbout,
            onTeam: widget.onTeam,
            onMember: () {},
          ),
        ),
      ],
    ),
  );

  Widget _hero() => Container(
    color: _ink,
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 700 ? 22 : 54,
      24,
      MediaQuery.sizeOf(context).width < 700 ? 22 : 54,
      76,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: widget.onHome,
              child: const DwellingIqLogo(size: 48),
            ),
            const Spacer(),
            const AuthButton(dark: true),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: widget.onHome,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('BACK TO DWELLINGSIQ'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 92),
        const Text(
          'BECOME A MEMBER',
          style: TextStyle(
            color: _lilac,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'One network.\nEvery side of the deal.',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.sizeOf(context).width < 700 ? 48 : 72,
            height: .94,
            fontWeight: FontWeight.w600,
            letterSpacing: -3,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: const Text(
            'Tell us whether you are buying property, acquiring a business or advising a Canadian transaction. Your answers shape the experience we build for you.',
            style: TextStyle(
              color: Color(0xFFC5C5D0),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _form() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 80),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                number: '01',
                title: 'Which best describes you?',
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 720
                      ? (constraints.maxWidth - 24) / 3
                      : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: MemberType.values
                        .map(
                          (type) => SizedBox(
                            width: width,
                            child: _RoleCard(
                              type: type,
                              selected: _type == type,
                              onTap: () => setState(() {
                                _type = type;
                                _specialties.clear();
                                _propertyTypes
                                  ..clear()
                                  ..add(
                                    type == MemberType.businessBuyer
                                        ? 'Open to opportunities'
                                        : 'Residential',
                                  );
                              }),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 58),
              const _SectionTitle(number: '02', title: 'Your details'),
              const SizedBox(height: 22),
              _Field(
                controller: _name,
                label: 'Full name',
                validator: _required,
              ),
              _Field(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : 'Enter a valid email',
              ),
              _Field(
                controller: _phone,
                label: 'Phone (optional)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 42),
              _type.isProfessional
                  ? _professionalQuestions()
                  : _buyerQuestions(),
              const SizedBox(height: 24),
              _Field(
                controller: _notes,
                label: 'Anything else we should know?',
                maxLines: 4,
              ),
              CheckboxListTile(
                value: _consent,
                onChanged: (value) => setState(() => _consent = value ?? false),
                contentPadding: EdgeInsets.zero,
                activeColor: _purple,
                title: const Text(
                  'I agree that DwellingsIQ may contact me about this application.',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_type.isProfessional)
                CheckboxListTile(
                  value: _professionalAttestation,
                  onChanged: (value) =>
                      setState(() => _professionalAttestation = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  activeColor: _purple,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I confirm this information is accurate and that I hold any licence required for the services I offer.',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Applications are reviewed. Verification cannot be purchased and may be suspended if information becomes inaccurate.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 22,
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_outward),
                label: Text(
                  _submitting ? 'SUBMITTING' : 'SUBMIT APPLICATION',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _professionalQuestions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionTitle(number: '03', title: 'Your practice'),
      const SizedBox(height: 22),
      _Field(
        controller: _company,
        label: 'Company or firm',
        validator: _required,
      ),
      _Field(controller: _license, label: 'Licence number (if applicable)'),
      _provincePicker('Primary licence province or territory'),
      const SizedBox(height: 20),
      const Text(
        'Choose the workspace you want to start with',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          const tiers = [
            (
              'free',
              'Free member',
              'Public profile, reviews and limited introductions.',
            ),
            (
              'professional',
              'Professional',
              'Deal Rooms, qualified introductions, pipeline and analytics.',
            ),
            (
              'featured',
              'Featured',
              'Everything in Professional plus clearly disclosed promotion.',
            ),
          ];
          final width = constraints.maxWidth >= 720
              ? (constraints.maxWidth - 20) / 3
              : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tiers
                .map(
                  (tier) => SizedBox(
                    width: width,
                    child: ChoiceChip(
                      selected: _requestedTier == tier.$1,
                      onSelected: (_) =>
                          setState(() => _requestedTier = tier.$1),
                      label: SizedBox(
                        height: 82,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tier.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tier.$3,
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 20),
      const Text(
        'What do you specialize in?',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      _chips(_professionalSpecialties, _specialties),
      const SizedBox(height: 18),
      _Field(
        controller: _markets,
        label: 'Cities or markets you serve (comma separated)',
        validator: _required,
      ),
      CheckboxListTile(
        value: _sponsorship,
        onChanged: (value) => setState(() => _sponsorship = value ?? false),
        contentPadding: EdgeInsets.zero,
        activeColor: _purple,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'I would like information about clearly disclosed sponsored placement.',
          style: TextStyle(fontSize: 13),
        ),
        subtitle: const Text(
          'Payment does not provide verification or guarantee ranking.',
          style: TextStyle(fontSize: 11),
        ),
      ),
    ],
  );

  Widget _buyerQuestions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionTitle(number: '03', title: 'What are you looking for?'),
      const SizedBox(height: 22),
      _Field(
        controller: _city,
        label: 'City, town or community in Canada',
        validator: _required,
      ),
      _provincePicker('Province or territory'),
      const SizedBox(height: 20),
      Text(
        _type == MemberType.businessBuyer
            ? 'Industries of interest'
            : 'Property type',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      _chips(
        _type == MemberType.businessBuyer
            ? _businessBuyerTypes
            : _buyerPropertyTypes,
        _propertyTypes,
      ),
      const SizedBox(height: 18),
      DropdownButtonFormField<String>(
        initialValue: _timeline,
        decoration: _decoration('When are you looking to buy?'),
        items:
            [
                  'As soon as possible',
                  'Within 3 months',
                  'Within 6 months',
                  'Within a year',
                  'Just researching',
                ]
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
        onChanged: (value) => setState(() => _timeline = value ?? _timeline),
      ),
      CheckboxListTile(
        value: _financing,
        onChanged: (value) => setState(() => _financing = value ?? false),
        contentPadding: EdgeInsets.zero,
        activeColor: _purple,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          _type == MemberType.businessBuyer
              ? 'I would like help comparing acquisition financing options.'
              : 'I would like help comparing mortgage or financing options.',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  );

  Widget _provincePicker(String label) => DropdownButtonFormField<String>(
    initialValue: _province,
    decoration: _decoration(label),
    items: MarketplaceService.provinces
        .map(
          (province) => DropdownMenuItem(
            value: province.code,
            child: Text('${province.name} (${province.code})'),
          ),
        )
        .toList(),
    onChanged: (value) => setState(() => _province = value ?? _province),
  );

  Widget _chips(List<String> options, Set<String> selected) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options
        .map(
          (value) => FilterChip(
            label: Text(value),
            selected: selected.contains(value),
            selectedColor: _lilac,
            onSelected: (isSelected) => setState(
              () => isSelected ? selected.add(value) : selected.remove(value),
            ),
          ),
        )
        .toList(),
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE1E1E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE1E1E8)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
  );

  Widget _success() => Container(
    color: _paper,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 110),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: _purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 28),
            const Text(
              'Application received.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 46,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Thanks, ${_name.text.trim()}. We’ll review your details and contact you at ${_email.text.trim()}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF666674),
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: widget.onHome,
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 18,
                ),
              ),
              child: const Text('RETURN HOME'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1E1E8)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.title});
  final String number;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        number,
        style: const TextStyle(
          color: _purple,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ),
    ],
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });
  final MemberType type;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected ? _ink : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? _purple : const Color(0xFFE1E1E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(type.icon, color: selected ? _lilac : _purple),
          const SizedBox(height: 18),
          Text(
            type.label,
            style: TextStyle(
              color: selected ? Colors.white : _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
