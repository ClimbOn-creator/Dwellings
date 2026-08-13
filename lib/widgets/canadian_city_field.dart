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
  void dispose() {
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
          onFieldSubmitted: (value) {
            final resolved = MarketplaceService.resolveCanadianCity(
              value,
              provinceCode: widget.provinceCode,
            );
            if (resolved != null) _accept(resolved);
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
                  (city) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city_outlined),
                    title: Text(city.city),
                    subtitle: Text('${city.region}, Canada'),
                    onTap: () => onSelected(city),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );
}
