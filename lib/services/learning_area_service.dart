import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_service.dart';
import 'learning_service.dart';

/// A broad community centre, never a device's precise coordinates.
class LearningArea {
  const LearningArea(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude, longitude;
  static double coarse(num v) => double.parse(v.toStringAsFixed(1));
  Map<String, dynamic> toJson() => {
    'area_name': name,
    'latitude': coarse(latitude),
    'longitude': coarse(longitude),
  };
  factory LearningArea.fromJson(Map<String, dynamic> j) => LearningArea(
    j['area_name'],
    coarse(j['latitude']),
    coarse(j['longitude']),
  );
}

class LearningAreaService {
  static const defaults = [
    LearningArea('Vancouver, BC', 49.3, -123.1),
    LearningArea('Victoria, BC', 48.4, -123.4),
    LearningArea('Nanaimo, BC', 49.2, -123.9),
    LearningArea('Courtenay, BC', 49.7, -125.0),
    LearningArea('Campbell River, BC', 50.0, -125.2),
    LearningArea('Kelowna, BC', 49.9, -119.5),
    LearningArea('Calgary, AB', 51.0, -114.1),
    LearningArea('Edmonton, AB', 53.5, -113.5),
    LearningArea('Toronto, ON', 43.7, -79.4),
    LearningArea('Ottawa, ON', 45.4, -75.7),
    LearningArea('Montréal, QC', 45.5, -73.6),
    LearningArea('Halifax, NS', 44.6, -63.6),
    LearningArea('Winnipeg, MB', 49.9, -97.1),
    LearningArea('Saskatoon, SK', 52.1, -106.7),
  ];
  static Future<List<LearningArea>> search(String query) async {
    final local = defaults
        .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (query.trim().length < 2) return local;
    try {
      final r = await http
          .get(
            Uri.https('geogratis.gc.ca', '/services/geoname/en/geonames.json', {
              'q': query.trim(),
              'category': 'O',
              'expand': 'items.province',
              'num': '12',
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return local;
      final items = (jsonDecode(r.body) as Map)['items'] as List? ?? [];
      final regions = {
        '59': 'BC',
        '48': 'AB',
        '47': 'SK',
        '46': 'MB',
        '35': 'ON',
        '24': 'QC',
        '13': 'NB',
        '12': 'NS',
        '11': 'PE',
        '10': 'NL',
        '60': 'YT',
        '61': 'NT',
        '62': 'NU',
      };
      final results = <LearningArea>[];
      for (final item in items) {
        if (item is! Map ||
            item['latitude'] is! num ||
            item['longitude'] is! num)
          continue;
        final code = (item['province'] as Map?)?['code']?.toString() ?? '';
        results.add(
          LearningArea(
            '${item['name']}, ${regions[code] ?? code}',
            LearningArea.coarse(item['latitude']),
            LearningArea.coarse(item['longitude']),
          ),
        );
      }
      return {
        for (final a in [...results, ...local]) a.name: a,
      }.values.toList();
    } catch (_) {
      return local;
    }
  }

  static String get _key =>
      'learning.area.${BackendService.user?.id ?? 'guest'}';
  static Future<LearningArea?> load() async {
    final uid = BackendService.user?.id;
    if (uid != null && BackendService.configured) {
      try {
        final j = await LearningService.client
            .from('learning_preferences')
            .select()
            .eq('user_id', uid)
            .maybeSingle();
        if (j != null) return LearningArea.fromJson(j);
      } catch (_) {}
    }
    final p = await SharedPreferences.getInstance();
    final value = p.getString(_key);
    return value == null ? null : LearningArea.fromJson(jsonDecode(value));
  }

  static Future<void> save(LearningArea area) async {
    final uid = BackendService.user?.id;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(area.toJson()));
    if (uid != null && BackendService.configured)
      await LearningService.client.from('learning_preferences').upsert({
        'user_id': uid,
        ...area.toJson(),
      });
  }
}
