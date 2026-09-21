import 'package:sembast/sembast_memory.dart';
import '../core/contracts/form_storage_adapter.dart';
import '../core/models/form_template.dart';
import '../core/models/form_submission.dart';
import '../core/models/outbox_mutation.dart';

/// Embedded, zero-configuration local NoSQL storage adapter powered by Sembast.
/// Runs in-memory by default (ideal for web/tests/demos) or takes a custom [Database] for persistent storage.
class DefaultSembastStorageAdapter implements FormStorageAdapter {
  Database? _db;
  final DatabaseFactory _databaseFactory;
  final String _databasePath;

  final StoreRef<String, Map<String, dynamic>> _templateStore =
      stringMapStoreFactory.store('form_templates');
  final StoreRef<String, Map<String, dynamic>> _submissionStore =
      stringMapStoreFactory.store('form_submissions');
  final StoreRef<String, Map<String, dynamic>> _outboxStore =
      stringMapStoreFactory.store('form_outbox');

  DefaultSembastStorageAdapter({
    Database? db,
    DatabaseFactory? databaseFactory,
    String databasePath = 'dynamic_form_engine.db',
  })  : _db = db,
        _databaseFactory = databaseFactory ?? databaseFactoryMemory,
        _databasePath = databasePath;

  Database get db {
    if (_db == null) {
      throw StateError(
        'DefaultSembastStorageAdapter has not been initialized. Call initialize() first.',
      );
    }
    return _db!;
  }

  @override
  Future<void> initialize() async {
    _db ??= await _databaseFactory.openDatabase(_databasePath);
  }

  // ---------------------------------------------------------------------------
  // Template Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveTemplate(FormTemplate template) async {
    await _templateStore.record(template.id).put(db, template.toMap());
  }

  @override
  Future<FormTemplate?> getTemplateById(String id) async {
    final map = await _templateStore.record(id).get(db);
    if (map == null) return null;
    return FormTemplate.fromMap(map);
  }

  @override
  Future<List<FormTemplate>> getTemplates({
    String? contextScope,
    bool includeArchived = false,
  }) async {
    final records = await _templateStore.find(
      db,
      finder: Finder(
        filter: Filter.custom((record) {
          final data = record.value as Map<String, dynamic>;
          if (!includeArchived && data['deletedAt'] != null) {
            return false;
          }
          if (contextScope != null && contextScope.isNotEmpty) {
            final scope = data['contextScope']?.toString();
            if (scope != null && scope != contextScope && scope != 'global') {
              return false;
            }
          }
          return true;
        }),
        sortOrders: [SortOrder('name')],
      ),
    );
    return records.map((r) => FormTemplate.fromMap(r.value)).toList();
  }

  @override
  Future<void> deleteTemplate(String id, {bool softDelete = true}) async {
    if (softDelete) {
      final existing = await getTemplateById(id);
      if (existing != null) {
        final updated = existing.copyWith(deletedAt: DateTime.now());
        await saveTemplate(updated);
      }
    } else {
      await _templateStore.record(id).delete(db);
    }
  }

  // ---------------------------------------------------------------------------
  // Submission Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSubmission(FormSubmission submission) async {
    await _submissionStore.record(submission.id).put(db, submission.toMap());
  }

  @override
  Future<FormSubmission?> getSubmissionById(String id) async {
    final map = await _submissionStore.record(id).get(db);
    if (map == null) return null;
    return FormSubmission.fromMap(map);
  }

  @override
  Future<List<FormSubmission>> getSubmissions({
    bool includeArchived = false,
  }) async {
    final records = await _submissionStore.find(
      db,
      finder: Finder(
        filter: Filter.custom((record) {
          final data = record.value as Map<String, dynamic>;
          if (!includeArchived && data['deletedAt'] != null) {
            return false;
          }
          return true;
        }),
        sortOrders: [SortOrder('submittedAt', false)],
      ),
    );
    return records.map((r) => FormSubmission.fromMap(r.value)).toList();
  }

  @override
  Future<List<FormSubmission>> querySubmissions({
    required String formId,
    String? contextId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final records = await _submissionStore.find(
      db,
      finder: Finder(
        filter: Filter.custom((record) {
          final data = record.value as Map<String, dynamic>;
          if (data['deletedAt'] != null) return false;
          if (data['formId'] != formId) return false;
          if (contextId != null &&
              contextId.isNotEmpty &&
              data['contextId'] != contextId) {
            return false;
          }
          if (startDate != null || endDate != null) {
            final subDate = DateTime.tryParse(data['submittedAt'] ?? '');
            if (subDate == null) return false;
            if (startDate != null && subDate.isBefore(startDate)) return false;
            if (endDate != null && subDate.isAfter(endDate)) return false;
          }
          return true;
        }),
        sortOrders: [SortOrder('submittedAt', false)],
        limit: limit,
        offset: offset,
      ),
    );
    return records.map((r) => FormSubmission.fromMap(r.value)).toList();
  }

  @override
  Future<void> deleteSubmission(String id, {bool softDelete = true}) async {
    if (softDelete) {
      final existing = await getSubmissionById(id);
      if (existing != null) {
        final updated = existing.copyWith(deletedAt: DateTime.now());
        await saveSubmission(updated);
      }
    } else {
      await _submissionStore.record(id).delete(db);
    }
  }

  // ---------------------------------------------------------------------------
  // Transactional Outbox (Offline Sync)
  // ---------------------------------------------------------------------------

  @override
  Future<void> queueOutboxMutation(OutboxMutation mutation) async {
    await _outboxStore.record(mutation.id).put(db, mutation.toMap());
  }

  @override
  Future<List<OutboxMutation>> getPendingOutboxMutations() async {
    final records = await _outboxStore.find(
      db,
      finder: Finder(
        filter: Filter.isNull('syncedAt'),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    return records.map((r) => OutboxMutation.fromMap(r.value)).toList();
  }

  @override
  Future<void> markOutboxMutationsSynced(List<String> mutationIds) async {
    final nowIso = DateTime.now().toIso8601String();
    for (final id in mutationIds) {
      final existing = await _outboxStore.record(id).get(db);
      if (existing != null) {
        final updated = Map<String, dynamic>.from(existing);
        updated['syncedAt'] = nowIso;
        await _outboxStore.record(id).put(db, updated);
      }
    }
  }
}
