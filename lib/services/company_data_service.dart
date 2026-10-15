import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

class CompanyDataReport {
  CompanyDataReport(this.data);
  final Map<String, dynamic> data;
  Map<String, dynamic> get totals =>
      Map<String, dynamic>.from(data['totals'] as Map? ?? {});
  List<Map<String, dynamic>> rows(String key) => (data[key] as List? ?? [])
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
  int number(String key) => (data[key] as num?)?.toInt() ?? 0;
  static String csvCell(Object? value) {
    var text = value?.toString() ?? '';
    // Prevent spreadsheet formula injection from profile names and other user-entered labels.
    if (RegExp(r'^\s*[=+@\-\t\r\n]').hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }

  String toCsv() {
    final lines = <List<Object?>>[
      ['Affinity company data', data['generated_at']],
      ['Selected period (days)', data['days']],
      ['Section', 'Label', 'Count', 'Database bytes'],
      for (final entry in totals.entries)
        ['All-time totals (unless labelled period)', entry.key, entry.value],
      for (final section in [
        'roles',
        'locations',
        'professions',
        'teams',
        'member_status',
        'pipeline',
        'new_accounts',
        'feature_visits',
        'inventory',
      ])
        for (final row in rows(section))
          [section, row['label'] ?? row['day'], row['count'], row['bytes']],
      ['File metadata', 'Uploaded file bytes', number('uploaded_file_bytes')],
      [
        'Definitions',
        'Locations are saved preferences; team selections are not confirmed hires.',
      ],
      [
        'Definitions',
        'Feature visits are opt-in signed-in counts, not unique visitors.',
      ],
      [
        'Definitions',
        'Inventory includes examples and system records; database bytes include indexes.',
      ],
    ];
    return '${lines.map((line) => line.map(csvCell).join(',')).join('\r\n')}\r\n';
  }
}

class CompanyDataService {
  static Future<bool> isOwner() async {
    if (!BackendService.configured || BackendService.user == null) return false;
    // Fail closed: a network error must never grant private dashboard access.
    try {
      return await Supabase.instance.client.rpc('is_affinity_data_owner') ==
          true;
    } catch (_) {
      return false;
    }
  }

  static Future<CompanyDataReport> load(int days) async {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in required');
    }
    final result = await Supabase.instance.client.rpc(
      'load_affinity_company_data',
      params: {'report_days': days},
    );
    return CompanyDataReport(Map<String, dynamic>.from(result as Map));
  }

  static Future<void> export(CompanyDataReport report) async {
    await FilePicker.platform.saveFile(
      dialogTitle: 'Save company data summary',
      fileName: 'affinity-company-data.csv',
      bytes: Uint8List.fromList(utf8.encode(report.toCsv())),
    );
  }
}
