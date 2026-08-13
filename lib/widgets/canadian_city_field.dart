import 'package:flutter/material.dart';

import '../services/marketplace_service.dart';

class CanadianCityField extends StatefulWidget {
  const CanadianCityField({
    super.key,
    required this.controller,
    required this.onSelected,
    this.provinceCode,
    this.label = 'City, town or community in Canada',
    this.required = true,
  });

  final TextEditingController controller;
  final ValueChanged<MarketplaceCity> onSelected;
  final String? provinceCode;
  final String label;
  final bool required;

  @override
  State<CanadianCityField> createState() => _CanadianCityFieldState();
}

class _CanadianCityFieldState extends State<CanadianCityField> {
  final _focus = FocusNode();
  MarketplaceCity? _selected;
  List<MarketplaceCity> _suggestions = const [];
  int _searchVersion = 0;
  bool _settingText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_search);
    _focus.addListener(_handleFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_search);
    _focus.removeListener(_handleFocus);
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_settingText) return;
    final query = widget.controller.text.trim();
    if (_selected?.city.toLowerCase() == query.toLowerCase()) {
      if (mounted && _suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }
    _selected = null;
    final version = ++_searchVersion;
    if (query.length < 2) {
      if (mounted) setState(() => _suggestions = const []);
      return;
    }
    final found = await MarketplaceService.searchCanadianCities(query);
    if (!mounted || version != _searchVersion) return;
    setState(() {
      _suggestions = widget.provinceCode == null
          ? found
          : found.where((city) => city.region == widget.provinceCode).toList();
    });
  }

  Future<void> _handleFocus() async {
    if (_focus.hasFocus || _suggestions.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted && !_focus.hasFocus && _suggestions.isNotEmpty) {
      _accept(_suggestions.first);
    }
  }

  void _accept(MarketplaceCity city) {
    _searchVersion++;
    _settingText = true;
    _selected = city;
    widget.controller.value = TextEditingValue(
      text: city.city,
      selection: TextSelection.collapsed(offset: city.city.length),
    );
    _settingText = false;
    setState(() => _suggestions = const []);
    _focus.unfocus();
    widget.onSelected(city);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.location_on_outlined),
          helperText: 'Choose a suggestion or press Enter to autofill.',
        ),
        validator: (value) {
          if (!widget.required && (value == null || value.trim().isEmpty)) {
            return null;
          }
          final normalized = (value ?? '').trim().toLowerCase();
          final selected = _selected?.city.toLowerCase() == normalized;
          return selected ||
                  MarketplaceService.resolveCanadianCity(
                        value ?? '',
                        provinceCode: widget.provinceCode,
                      ) !=
                      null
              ? null
              : 'Choose a recognized Canadian city from the list.';
        },
        onFieldSubmitted: (_) {
          if (_suggestions.isNotEmpty) _accept(_suggestions.first);
        },
      ),
      if (_suggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCD6F1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26050510),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final city = _suggestions[index];
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _accept(city),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city_outlined),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '${city.city}, ${city.region}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Text(
                          'USE',
                          style: TextStyle(
                            color: Color(0xFF7657FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}
