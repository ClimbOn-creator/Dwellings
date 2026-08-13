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

  @override
  void initState() {
    super.initState();
    _focus.addListener(_handleFocus);
  }

  Future<void> _handleFocus() async {
    if (_focus.hasFocus || widget.controller.text.trim().length < 2) return;
    final options = await MarketplaceService.searchCanadianCities(
      widget.controller.text,
    );
    if (!mounted || options.isEmpty) return;
    _accept(options.first);
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocus);
    _focus.dispose();
    super.dispose();
  }

  void _accept(MarketplaceCity city) {
    _selected = city;
    widget.controller.text = city.city;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    widget.onSelected(city);
  }

  @override
  Widget build(BuildContext context) => RawAutocomplete<MarketplaceCity>(
    textEditingController: widget.controller,
    focusNode: _focus,
    displayStringForOption: (city) => city.city,
    optionsBuilder: (value) async {
      final cities = await MarketplaceService.searchCanadianCities(value.text);
      return widget.provinceCode == null
          ? cities
          : cities.where((city) => city.region == widget.provinceCode);
    },
    onSelected: _accept,
    fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.location_on_outlined),
            helperText: 'Choose a suggestion so we can match the right market.',
          ),
          validator: (value) {
            if (!widget.required && (value == null || value.trim().isEmpty)) {
              return null;
            }
            final normalized = (value ?? '').trim().toLowerCase();
            final isSelected = _selected?.city.toLowerCase() == normalized;
            return !isSelected &&
                    MarketplaceService.resolveCanadianCity(
                          value ?? '',
                          provinceCode: widget.provinceCode,
                        ) ==
                        null
                ? 'Choose a recognized Canadian city from the list.'
                : null;
          },
          onFieldSubmitted: (value) async {
            final choices = await MarketplaceService.searchCanadianCities(
              value,
            );
            if (choices.isNotEmpty) _accept(choices.first);
            onSubmitted();
          },
        ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 300),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            children: options
                .map(
                  (city) => InkWell(
                    onTap: () => onSelected(city),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city.city,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text('${city.region}, Canada'),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_outward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );
}
