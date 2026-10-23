import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../services/pact_profile_service.dart';
import '../services/pact_professional_service.dart';
import '../widgets/pact_mobile_surface.dart';

class PactProfessionalEditor extends StatefulWidget {
  const PactProfessionalEditor({
    super.key,
    required this.profile,
    required this.professional,
  });
  final AccountProfile profile;
  final MarketplaceProvider professional;
  @override
  State<PactProfessionalEditor> createState() => _PactProfessionalEditorState();
}

class _PactProfessionalEditorState extends State<PactProfessionalEditor> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late final Map<String, Set<String>> _selected;
  late final Map<String, List<Map<String, TextEditingController>>> _entries;
  late String _availability, _currency;
  bool _saving = false;
  String? _error;
  static const groups = <String, Map<String, String>>{
    'employment': {
      'title': 'Role / job title',
      'organization': 'Company or practice',
      'start_year': 'Start year',
      'end_year': 'End year (blank = current)',
      'description': 'Responsibilities and relevant work',
    },
    'deals': {
      'title': 'Anonymous transaction title',
      'role': 'Your involvement',
      'year': 'Year',
      'summary': 'Relevant work and outcome (no client names)',
    },
    'credentials': {
      'title': 'Credential / licence name',
      'issuer': 'Issuing body',
      'number': 'Public registration number (optional)',
      'jurisdiction': 'Jurisdiction code, e.g. CA-BC',
      'expires_on': 'Expiry date (YYYY-MM-DD, optional)',
    },
  };
  @override
  void initState() {
    super.initState();
    final b = ProfessionalBackground(
      widget.professional.professionalBackground,
    );
    _fields = {
      for (final key in ['deal_min', 'deal_max'])
        key: TextEditingController(text: b.text(key)),
      'jurisdictions': TextEditingController(
        text: b.values('jurisdictions').join(', '),
      ),
    };
    _selected = {
      for (final key in ['services', 'industries', 'transaction_types'])
        key: b.values(key).toSet(),
    };
    _availability = pactAvailability.containsKey(b.text('availability'))
        ? b.text('availability')
        : 'unknown';
    _currency = pactCurrencies.contains(b.text('currency'))
        ? b.text('currency')
        : 'CAD';
    _entries = {
      for (final key in groups.keys)
        key: [for (final row in b.entries(key)) _row(key, row)],
    };
  }

  Map<String, TextEditingController> _row(
    String group, [
    Map<String, dynamic> data = const {},
  ]) => {
    for (final key in groups[group]!.keys)
      key: TextEditingController(text: '${data[key] ?? ''}'),
    if (group == 'credentials')
      'kind': TextEditingController(text: '${data['kind'] ?? ''}'),
    if (group == 'deals') ...{
      for (final key in ['industry', 'transaction_type'])
        key: TextEditingController(text: '${data[key] ?? ''}'),
    },
  };
  final _retired = <TextEditingController>[];
  @override
  void dispose() {
    for (final c in [
      ..._fields.values,
      ..._retired,
      ..._entries.values.expand((rows) => rows).expand((r) => r.values),
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _list(String text) => text
      .split(',')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList();
  Future<void> _save() async {
    if (!_form.currentState!.validate() ||
        BackendService.user?.id != widget.profile.id) {
      return;
    }
    final data = <String, dynamic>{
      for (final key in _selected.keys) key: _selected[key]!.toList(),
      'jurisdictions': _list(_fields['jurisdictions']!.text),
      'availability': _availability,
      'currency': _currency,
      for (final key in ['deal_min', 'deal_max'])
        if (_fields[key]!.text.trim().isNotEmpty)
          key: num.parse(_fields[key]!.text.trim()),
      for (final group in groups.keys)
        group: [
          for (final row in _entries[group]!)
            {
              for (final field in row.entries)
                field.key: field.value.text.trim(),
            },
        ],
    };
    if (utf8.encode(jsonEncode(data)).length > 24576) {
      setState(
        () => _error =
            'Keep your public experience under 24 KB. Shorten the descriptions and try again.',
      );
      return;
    }
    if (data['deal_min'] != null &&
        data['deal_max'] != null &&
        (data['deal_min'] as num) > (data['deal_max'] as num)) {
      setState(
        () => _error = 'The minimum deal size must not exceed the maximum.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PactProfileService.save(
        profile: widget.profile,
        details: {
          'full_name': widget.profile.fullName,
          'job_title': widget.profile.jobTitle,
          'company_name': widget.profile.companyName,
          'bio': widget.profile.bio,
          'professional_background': data,
        },
      );
      if (mounted && BackendService.user?.id == widget.profile.id) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save. Your changes are still here. If another device changed your profile, reopen this editor before saving again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
  Widget _choices(String key, Map<String, String> labels) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final entry in {
        ...labels,
        for (final existing in _selected[key]!)
          if (!labels.containsKey(existing)) existing: existing,
      }.entries)
        FilterChip(
          label: Text(entry.value),
          selected: _selected[key]!.contains(entry.key),
          onSelected: _saving
              ? null
              : (v) => setState(() {
                  if (v && _selected[key]!.length < 16) {
                    _selected[key]!.add(entry.key);
                  } else if (!v) {
                    _selected[key]!.remove(entry.key);
                  }
                }),
        ),
    ],
  );
  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    int lines = 1,
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      enabled: !_saving,
      minLines: lines,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F6FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (text) {
        final v = (text ?? '').trim();
        if (required && v.isEmpty) return 'Complete this field.';
        final name = key.split('.').last;
        if (v.length >
                (['summary', 'description'].contains(name) ? 1200 : 160) &&
            name != 'jurisdictions') {
          return 'Please shorten this field.';
        }
        if (['deal_min', 'deal_max'].contains(name) && v.isNotEmpty) {
          final n = num.tryParse(v);
          if (n == null || !n.isFinite || n < 0 || n > 1000000000000) {
            return 'Enter a valid amount without commas.';
          }
        }
        if (name == 'jurisdictions' &&
            (_list(v).length > 16 ||
                _list(v).any(
                  (s) => !RegExp(r'^[A-Z]{2}(-[A-Z0-9]{1,3})?$').hasMatch(s),
                ))) {
          return 'Use up to 16 jurisdiction codes, e.g. CA-BC.';
        }
        if (name == 'jurisdiction' &&
            !RegExp(r'^[A-Z]{2}(-[A-Z0-9]{1,3})?$').hasMatch(v)) {
          return 'Use a jurisdiction code, e.g. CA-BC.';
        }
        if (['year', 'start_year', 'end_year'].contains(name) &&
            v.isNotEmpty &&
            !RegExp(r'^(19|20)[0-9]{2}$').hasMatch(v)) {
          return 'Enter a four-digit year.';
        }
        if (name == 'expires_on' && v.isNotEmpty) {
          final d = DateTime.tryParse(v);
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ||
              d == null ||
              d.toIso8601String().substring(0, 10) != v) {
            return 'Use a valid YYYY-MM-DD date.';
          }
        }
        return null;
      },
    ),
  );
  Widget _records(String group, String title) => _section(title, [
    for (var i = 0; i < _entries[group]!.length; i++) ...[
      Row(
        children: [
          Expanded(
            child: Text(
              '$title ${i + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Remove $group entry ${i + 1}',
            onPressed: _saving
                ? null
                : () => setState(() {
                    _retired.addAll(_entries[group]!.removeAt(i).values);
                  }),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      for (final field in groups[group]!.entries)
        _field(
          '$group.$i.${field.key}',
          field.value,
          _entries[group]![i][field.key]!,
          lines: ['summary', 'description'].contains(field.key) ? 4 : 1,
          required:
              field.key == 'title' ||
              group == 'credentials' &&
                  ['issuer', 'jurisdiction'].contains(field.key),
        ),
      if (group == 'credentials')
        _dropdown(
          'Credential type',
          _entries[group]![i]['kind']!,
          pactCredentialKinds,
          required: true,
        ),
      if (group == 'deals') ...[
        _dropdown('Industry', _entries[group]![i]['industry']!, pactIndustries),
        _dropdown(
          'Transaction type',
          _entries[group]![i]['transaction_type']!,
          pactTransactions,
        ),
      ],
      const Divider(),
    ],
    if (_entries[group]!.length < 12)
      OutlinedButton.icon(
        onPressed: _saving
            ? null
            : () => setState(() => _entries[group]!.add(_row(group))),
        icon: const Icon(Icons.add),
        label: Text(
          'Add ${group == 'employment'
              ? 'role'
              : group == 'deals'
              ? 'deal experience'
              : 'credential'}',
        ),
      ),
  ]);
  Widget _dropdown(
    String label,
    TextEditingController controller,
    Map<String, String> options, {
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      initialValue: options.containsKey(controller.text)
          ? controller.text
          : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      validator: (v) =>
          required && v == null ? 'Choose a credential type.' : null,
      onChanged: _saving ? null : (v) => controller.text = v ?? '',
    ),
  );
  @override
  Widget build(BuildContext context) => PactMobileSurface(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Experience & specialties'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Your experience helps people understand your fit for a deal. These details are public and self-reported until credentials are independently verified.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _section('Services & specialties', [
                _choices('services', pactServices),
              ]),
              _section('Industry experience', [
                _choices('industries', pactIndustries),
              ]),
              _section('Transaction experience', [
                _choices('transaction_types', pactTransactions),
              ]),
              _section('Practice details', [
                _field(
                  'jurisdictions',
                  'Service jurisdictions (e.g. CA-BC, CA-AB)',
                  _fields['jurisdictions']!,
                ),
                const Text(
                  'Service jurisdictions describe where you work. They do not verify your licence.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _availability,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Availability'),
                  items: [
                    for (final e in pactAvailability.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _availability = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Deal currency'),
                  items: [
                    for (final c in pactCurrencies)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _currency = v!),
                ),
                const SizedBox(height: 16),
                _field(
                  'deal_min',
                  'Typical minimum deal size',
                  _fields['deal_min']!,
                ),
                _field(
                  'deal_max',
                  'Typical maximum deal size',
                  _fields['deal_max']!,
                ),
              ]),
              _records('employment', 'Experience'),
              _records('deals', 'Deal experience'),
              const Text(
                'Use anonymous transaction descriptions. Do not include client names, private documents or confidential financial details.',
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 16),
              _records('credentials', 'Credentials'),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save experience'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
