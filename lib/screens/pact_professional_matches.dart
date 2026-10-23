import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/deal_room_service.dart';
import '../services/marketplace_service.dart';
import '../services/pact_professional_service.dart';
import '../widgets/pact_mobile_surface.dart';
import '../widgets/profile_photo.dart';
import 'member_profile_page.dart';

class PactProfessionalMatchesPage extends StatefulWidget {
  const PactProfessionalMatchesPage({
    super.key,
    this.onContact,
    this.loadDeals,
    this.loadMatches,
  });
  final Future<void> Function(String providerId)? onContact;
  final Future<List<DealRoom>> Function()? loadDeals;
  final Future<List<ProfessionalMatch>> Function(Map<String, dynamic>)?
  loadMatches;
  @override
  State<PactProfessionalMatchesPage> createState() =>
      _PactProfessionalMatchesPageState();
}

class _PactProfessionalMatchesPageState
    extends State<PactProfessionalMatchesPage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _jurisdiction = TextEditingController();
  late final Future<List<DealRoom>> _deals =
      (widget.loadDeals ?? DealRoomService.loadRooms)();
  final String? _owner = BackendService.user?.id;
  String? _deal, _profession, _service, _industry;
  String _transaction = 'business_acquisition', _currency = 'CAD';
  bool _credential = false, _loading = false;
  int _request = 0;
  String? _error;
  List<ProfessionalMatch>? _matches;
  StreamSubscription<dynamic>? _auth;
  @override
  void initState() {
    super.initState();
    _auth = BackendService.authChanges?.listen((_) {
      if (mounted && BackendService.user?.id != _owner) {
        setState(() {
          _request++;
          _matches = null;
          _amount.clear();
          _jurisdiction.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _auth?.cancel();
    _request++;
    _amount.dispose();
    _jurisdiction.dispose();
    super.dispose();
  }

  Future<void> _match() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _matches = null;
    });
    try {
      final matches =
          await (widget.loadMatches ?? PactProfessionalService.match)({
            'profession': _profession,
            'service': _service,
            'industry': _industry,
            'transaction_type': _transaction,
            'currency': _currency,
            'amount': num.tryParse(_amount.text.trim()),
            'jurisdiction': _jurisdiction.text.trim().toUpperCase(),
            'require_credential': _credential,
          });
      if (!mounted ||
          request != _request ||
          BackendService.user?.id != _owner) {
        return;
      }
      setState(() => _matches = matches);
    } catch (_) {
      if (mounted && request == _request) {
        setState(
          () => _error =
              'Matches could not load. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Widget _select(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null ? 'Choose $label.' : null,
      items: [
        for (final e in options.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: _loading
          ? null
          : (v) {
              setState(() {
                _matches = null;
                _error = null;
              });
              changed(v);
            },
    ),
  );
  void _useDeal(DealRoom room) {
    setState(() {
      _deal = room.id;
      _amount.text = room.purchasePrice > 0
          ? room.purchasePrice.toStringAsFixed(0)
          : '';
      _currency = pactCurrencies.contains(room.currency)
          ? room.currency
          : 'CAD';
      _transaction = room.isBusiness ? 'business_acquisition' : 'mortgage';
      final parts = room.city.toUpperCase().split(RegExp(r'[^A-Z]+'));
      final region = pactJurisdictions.keys
          .where((v) => parts.contains(v.split('-').last))
          .firstOrNull;
      _jurisdiction.text = region ?? '';
      final industry = '${room.propertySnapshot['industry'] ?? ''}'
          .toLowerCase();
      _industry = pactIndustries.entries
          .where((v) => v.key == industry || v.value.toLowerCase() == industry)
          .firstOrNull
          ?.key;
      _matches = null;
    });
  }

  Future<void> _profile(ProfessionalMatch match) async {
    try {
      final profile = await MarketplaceService.loadProvider(match.provider.id);
      if (!mounted || BackendService.user?.id != _owner) return;
      if (profile == null) {
        setState(
          () => _error =
              'This profile is no longer available. Refresh your matches.',
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemberProfilePage(
            provider: profile,
            onMessage: widget.onContact == null
                ? null
                : () => widget.onContact!(profile.id),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'This profile could not load. Please retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => BackendService.user?.id != _owner
      ? Scaffold(
          appBar: AppBar(title: const Text('Pact')),
          body: const Center(
            child: Text(
              'Your account changed. Return to your dashboard and sign in again.',
            ),
          ),
        )
      : PactMobileSurface(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Find the right professional'),
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      const Text(
                        'Match experience to your deal',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Recommendations explain relevant experience. They do not predict transaction success. Your private deal is not shared with members.',
                        style: TextStyle(height: 1.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 22),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<List<DealRoom>>(
                                  future: _deals,
                                  builder: (context, snapshot) {
                                    final rows = snapshot.data ?? [];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (snapshot.hasError)
                                          const Text(
                                            'Saved deals could not load. You can enter matching criteria below.',
                                          ),
                                        if (rows.isNotEmpty)
                                          DropdownButtonFormField<String>(
                                            initialValue: _deal,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Use a saved deal (optional)',
                                            ),
                                            items: [
                                              for (final room in rows)
                                                DropdownMenuItem(
                                                  value: room.id,
                                                  child: Text(
                                                    room.title,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                            onChanged: _loading
                                                ? null
                                                : (v) => _useDeal(
                                                    rows.firstWhere(
                                                      (r) => r.id == v,
                                                    ),
                                                  ),
                                          ),
                                        const SizedBox(height: 18),
                                      ],
                                    );
                                  },
                                ),
                                _select(
                                  'Profession',
                                  _profession,
                                  {
                                    for (final category
                                        in ProviderCategory.values)
                                      category.databaseValue: category.label,
                                  },
                                  (v) => setState(() => _profession = v),
                                ),
                                _select(
                                  'Service needed',
                                  _service,
                                  pactServices,
                                  (v) => setState(() => _service = v),
                                ),
                                // Keys reset initialValue when a saved deal changes these selections.
                                KeyedSubtree(
                                  key: ValueKey('industry-$_deal-$_industry'),
                                  child: _select(
                                    'Industry',
                                    _industry,
                                    pactIndustries,
                                    (v) => setState(() => _industry = v),
                                  ),
                                ),
                                KeyedSubtree(
                                  key: ValueKey('transaction-$_transaction'),
                                  child: _select(
                                    'Transaction type',
                                    _transaction,
                                    pactTransactions,
                                    (v) => setState(() => _transaction = v!),
                                  ),
                                ),
                                TextFormField(
                                  controller: _jurisdiction,
                                  onChanged: (_) =>
                                      setState(() => _matches = null),
                                  enabled: !_loading,
                                  decoration: const InputDecoration(
                                    labelText: 'Service jurisdiction code',
                                    hintText: 'CA-BC',
                                  ),
                                  validator: (v) =>
                                      !RegExp(
                                        r'^[A-Z]{2}(-[A-Z0-9]{1,3})?$',
                                      ).hasMatch((v ?? '').trim().toUpperCase())
                                      ? 'Use a jurisdiction code, e.g. CA-BC.'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pactJurisdictions.entries
                                      .map(
                                        (v) =>
                                            '${v.key} · ${v.value.split(',').first}',
                                      )
                                      .take(5)
                                      .join('   '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                KeyedSubtree(
                                  key: ValueKey('currency-$_currency'),
                                  child: _select(
                                    'Currency',
                                    _currency,
                                    {
                                      for (final code in pactCurrencies)
                                        code: code,
                                    },
                                    (v) => setState(() => _currency = v!),
                                  ),
                                ),
                                TextFormField(
                                  controller: _amount,
                                  onChanged: (_) =>
                                      setState(() => _matches = null),
                                  enabled: !_loading,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Deal size (optional)',
                                    hintText: '1000000',
                                  ),
                                  validator: (v) {
                                    if ((v ?? '').trim().isEmpty) return null;
                                    final n = num.tryParse(v!.trim());
                                    return n == null ||
                                            !n.isFinite ||
                                            n < 0 ||
                                            n > 1000000000000
                                        ? 'Enter a valid amount without commas.'
                                        : null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Require a verified professional credential',
                                  ),
                                  value: _credential,
                                  subtitle: const Text(
                                    'Always required for lawyers, realtors and mortgage brokers. Verification must cover this jurisdiction.',
                                  ),
                                  onChanged: _loading
                                      ? null
                                      : (v) => setState(() {
                                          _credential = v!;
                                          _matches = null;
                                        }),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _loading ? null : _match,
                                  icon: const Icon(Icons.manage_search),
                                  label: Text(
                                    _loading
                                        ? 'Finding matches…'
                                        : 'Find matches',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (_matches != null) ...[
                        const Text(
                          'Why these professionals?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Specialty 35% · industry 30% · transaction type and size 25% · location 10%. Experience is self-reported. Missing information earns no points; paid tiers, About wording and review counts do not improve the score.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_matches!.isEmpty)
                          const Text(
                            'No available members were found for this profession. Try another service or check again later.',
                          ),
                        for (final match in _matches!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ProfilePhoto(
                                          size: 48,
                                          photoUrl: match.provider.photoUrl,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                match.provider.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                match.provider.company,
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Chip(
                                      label: Text(match.label),
                                      side: BorderSide.none,
                                      backgroundColor: const Color(0xFFF0EDFF),
                                    ),
                                    for (final reason in match.reasons)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text('• $reason'),
                                      ),
                                    for (final missing in match.missing)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'Check · $missing',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 14),
                                    OutlinedButton(
                                      onPressed: () => _profile(match),
                                      child: const Text('View profile'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}
