import 'dart:convert';
import '../core/models/form_template.dart';
import '../core/contracts/form_storage_adapter.dart';

/// Service to import, export, and synchronize JSON form templates with storage.
class TemplateSyncService {
  final FormStorageAdapter storageAdapter;

  const TemplateSyncService(this.storageAdapter);

  /// Imports and up-serts templates from a JSON string (single template map or list of template maps).
  Future<int> importTemplatesFromJson(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    final List<dynamic> list = decoded is List ? decoded : [decoded];

    int count = 0;
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final template = FormTemplate.fromMap(item);
        await storageAdapter.saveTemplate(template);
        count++;
      }
    }
    return count;
  }

  /// Serializes all active templates into a JSON string.
  Future<String> exportTemplatesToJson({String? contextScope}) async {
    final templates = await storageAdapter.getTemplates(
      contextScope: contextScope,
      includeArchived: false,
    );
    final list = templates.map((t) => t.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}
