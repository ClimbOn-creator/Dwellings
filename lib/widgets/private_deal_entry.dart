import 'package:flutter/material.dart';
import '../screens/deal_rooms_page.dart' show DealIntakeDetails;
import '../services/deal_intake_fields.dart';
import '../services/deal_room_service.dart';
import 'dashboard_ui.dart';
import 'site_copy_text.dart';

class PrivateDealEntry extends StatefulWidget {
  const PrivateDealEntry({
    super.key,
    required this.onSave,
    required this.onHome,
    required this.onOpen,
    this.embedded = false,
  });
  final Future<DealRoom> Function(DealIntakeDetails) onSave;
  final VoidCallback onHome;
  final ValueChanged<DealRoom> onOpen;
  final bool embedded;
  @override
  State<PrivateDealEntry> createState() => _PrivateDealEntryState();
}

class _PrivateDealEntryState extends State<PrivateDealEntry> {
  final _fields = {
    for (final key in [
      'source_url',
      'title',
      'location',
      'deal_details',
      'price',
      'currency',
      'country',
      'annual_revenue',
      'reported_ebitda',
    ])
      key: TextEditingController(),
  };
  bool _saving = false;
  String? _error;
  DealRoom? _saved;
  String value(String key) => _fields[key]!.text.trim();
  @override
  void initState() {
    super.initState();
    _fields['currency']!.text = 'CAD';
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final error = value('title').isEmpty
        ? 'Enter a business name or a short deal title.'
        : validateDealIntake(
            {
              'source_url': value('source_url'),
              'currency': value('currency'),
              'country': value('country').isEmpty
                  ? 'Unknown'
                  : value('country'),
            },
            [value('price'), value('annual_revenue'), value('reported_ebitda')],
          );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final room = await widget.onSave(
        DealIntakeDetails(
          title: value('title'),
          kind: 'business',
          location: value('location'),
          purchasePrice:
              double.tryParse(value('price').replaceAll(',', '')) ?? 0,
          goals: '',
          targetCloseDate: null,
          profileSnapshot: {
            'source_name': Uri.tryParse(value('source_url'))?.host ?? '',
            'source_url': value('source_url'),
            'deal_details': value('deal_details'),
            'country': value('country').isEmpty ? 'Unknown' : value('country'),
            'currency': value('currency').toUpperCase(),
            'asking_price_known': value('price').isNotEmpty,
            for (final key in ['annual_revenue', 'reported_ebitda'])
              if (value(key).isNotEmpty)
                key: double.parse(value(key).replaceAll(',', '')),
            'entry_source': 'buyer_pipeline',
          },
        ),
      );
      if (mounted) setState(() => _saved = room);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not save your private deal. Your entries are still here. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String key,
    String label, {
    int lines = 1,
    bool money = false,
  }) => TextField(
    key: ValueKey('private-deal-$key'),
    controller: _fields[key],
    enabled: !_saving,
    minLines: lines,
    maxLines: lines,
    keyboardType: money
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : key == 'source_url'
        ? TextInputType.url
        : TextInputType.text,
    decoration: InputDecoration(
      label: SiteCopyText('buyer.pipeline.entry.$key.label', label),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: DashboardUi.panel(
            child: saved != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF208465),
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      const SiteCopyText(
                        'buyer.pipeline.saved.title',
                        'Saved to your private deals',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(saved.title),
                      const SizedBox(height: 8),
                      const SiteCopyText(
                        'buyer.pipeline.saved.body',
                        'Your deal is now on Home. It has not been published or shared with advisers.',
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            onPressed: widget.onHome,
                            child: const SiteCopyText(
                              'buyer.pipeline.saved.home',
                              'View on Home',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => widget.onOpen(saved),
                            child: const SiteCopyText(
                              'buyer.pipeline.saved.open',
                              'Open deal workspace',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              for (final c in _fields.values) {
                                c.clear();
                              }
                              _fields['currency']!.text = 'CAD';
                              setState(() => _saved = null);
                            },
                            child: const SiteCopyText(
                              'buyer.pipeline.saved.another',
                              'Add another deal',
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: DashboardUi.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: SiteCopyText(
                              'buyer.pipeline.entry.eyebrow',
                              'YOUR PRIVATE PIPELINE',
                              style: TextStyle(
                                color: DashboardUi.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SiteCopyText(
                        'buyer.pipeline.entry.title',
                        'Add a deal you found online',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SiteCopyText(
                        'buyer.pipeline.entry.intro',
                        'Save the listing link and the details you know. Unknown figures can stay blank. Your saved deal will appear on Home.',
                      ),
                      const SizedBox(height: 24),
                      _field('source_url', 'Listing link (optional)'),
                      const SizedBox(height: 8),
                      const SiteCopyText(
                        'buyer.pipeline.entry.linkHint',
                        'Links are saved as references. Listing details are not imported automatically.',
                        style: TextStyle(
                          color: DashboardUi.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _field('title', 'Business name or deal title'),
                      const SizedBox(height: 20),
                      _field('location', 'City / province (optional)'),
                      const SizedBox(height: 20),
                      _field(
                        'deal_details',
                        'What does the business do? (optional)',
                        lines: 3,
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, box) => box.maxWidth < 500
                            ? Column(
                                children: [
                                  _field(
                                    'price',
                                    'Asking price (optional)',
                                    money: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _field('currency', 'Currency code'),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _field(
                                      'price',
                                      'Asking price (optional)',
                                      money: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 150,
                                    child: _field('currency', 'Currency code'),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.white,
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const SiteCopyText(
                            'buyer.pipeline.entry.more',
                            'More details (optional)',
                          ),
                          children: [
                            _field(
                              'country',
                              'Country / jurisdiction (optional)',
                            ),
                            const SizedBox(height: 20),
                            _field(
                              'annual_revenue',
                              'Annual revenue (optional)',
                              money: true,
                            ),
                            const SizedBox(height: 20),
                            _field(
                              'reported_ebitda',
                              'Annual earnings / EBITDA (optional)',
                              money: true,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SiteCopyText(
                        'buyer.pipeline.entry.privacy',
                        'Only your account can access this deal. Saving does not publish it, contact the seller or invite advisers.',
                        style: TextStyle(color: DashboardUi.muted),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFB3261E)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_outline, size: 18),
                          label: _saving
                              ? const SiteCopyText(
                                  'buyer.pipeline.entry.saving',
                                  'Saving private deal…',
                                )
                              : const SiteCopyText(
                                  'buyer.pipeline.entry.save',
                                  'Save private deal',
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return widget.embedded ? body : SingleChildScrollView(child: body);
  }
}
