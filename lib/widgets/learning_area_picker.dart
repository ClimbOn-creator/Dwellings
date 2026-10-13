import 'dart:async';
import 'package:flutter/material.dart';
import '../services/device_location_service.dart';
import '../services/learning_area_service.dart';

Future<LearningArea?> chooseLearningArea(BuildContext context) =>
    showDialog<LearningArea>(
      context: context,
      builder: (_) => const LearningAreaPicker(),
    );

class LearningAreaPicker extends StatefulWidget {
  const LearningAreaPicker({super.key});
  @override
  State<LearningAreaPicker> createState() => _LearningAreaPickerState();
}

class _LearningAreaPickerState extends State<LearningAreaPicker> {
  final query = TextEditingController();
  Timer? debounce;
  int generation = 0;
  bool busy = false;
  String? error;
  List<LearningArea> areas = LearningAreaService.defaults;
  @override
  void dispose() {
    generation++;
    debounce?.cancel();
    query.dispose();
    super.dispose();
  }

  void search(String value) {
    debounce?.cancel();
    final run = ++generation;
    debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => busy = true);
      final results = await LearningAreaService.search(value);
      if (mounted && run == generation)
        setState(() {
          areas = results;
          busy = false;
        });
    });
  }

  Future<void> locate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final location = await DeviceLocationService.locateCanadianCity();
      // Device coordinates are discarded: only the looked-up community centre is used.
      final results = await LearningAreaService.search(location.city.city);
      final matches = results.where((a) => a.name == location.city.label);
      if (matches.isEmpty)
        throw StateError('Choose your community from the search results.');
      if (mounted) Navigator.pop(context, matches.first);
    } catch (_) {
      if (mounted)
        setState(
          () =>
              error = 'Location was unavailable. Search for your city instead.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose a community'),
    content: SizedBox(
      width: 480,
      height: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your feed shows posts within about 200 km of this community. We use a broad area, not your exact address.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: query,
            onChanged: search,
            decoration: const InputDecoration(
              labelText: 'Search Canadian communities',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          TextButton.icon(
            onPressed: busy ? null : locate,
            icon: const Icon(Icons.my_location),
            label: const Text('Find my community'),
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          Expanded(
            child: areas.isEmpty
                ? const Center(
                    child: Text('No communities found. Try a nearby city.'),
                  )
                : ListView(
                    children: [
                      for (final area in areas)
                        ListTile(
                          title: Text(area.name),
                          leading: const Icon(Icons.location_on_outlined),
                          onTap: () => Navigator.pop(context, area),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}
