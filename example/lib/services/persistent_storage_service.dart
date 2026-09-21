import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

class PersistentStorageService implements FormStorageAdapter {
  static const String _dbName = 'dynamic_form_engine.db';
  static const String _templatesStore = 'form_templates';
  static const String _submissionsStore = 'form_submissions';
  static const String _outboxStore = 'form_outbox';

  late Database _db;
  final StoreRef<String, Map<String, dynamic>> _templateStoreRef =
      stringMapStoreFactory.store(_templatesStore);
  final StoreRef<String, Map<String, dynamic>> _submissionStoreRef =
      stringMapStoreFactory.store(_submissionsStore);
  final StoreRef<String, Map<String, dynamic>> _outboxStoreRef =
      stringMapStoreFactory.store(_outboxStore);

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      try {
        // IndexedDB persistence on Web
        final factory = databaseFactoryWeb;
        _db = await factory.openDatabase(_dbName);
      } catch (e) {
        debugPrint(
          '[PersistentStorageService] Warning: Failed to open IndexedDB on Web ($e). '
          'Falling back to in-memory database.',
        );
        _db = await databaseFactoryMemory.openDatabase(_dbName);
      }
    } else {
      // Persistent File I/O on Android, iOS, macOS, Linux, Windows
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(appDocDir.path, _dbName);
      final factory = databaseFactoryIo;
      _db = await factory.openDatabase(dbPath);
    }

    _isInitialized = true;
  }

  @override
  Future<List<FormTemplate>> getTemplates({
    String? contextScope,
    bool includeArchived = false,
  }) async {
    _ensureInitialized();
    try {
      final records = await _templateStoreRef.find(
        _db,
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
        ),
      );
      return records.map((record) => FormTemplate.fromJson(record.value)).toList();
    } catch (e) {
      if (kIsWeb) {
        debugPrint('[PersistentStorageService] Web getTemplates error: $e');
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<FormTemplate?> getTemplate(String id) async {
    _ensureInitialized();
    try {
      final data = await _templateStoreRef.record(id).get(_db);
      if (data == null) return null;
      return FormTemplate.fromJson(data);
    } catch (e) {
      if (kIsWeb) {
        debugPrint('[PersistentStorageService] Web getTemplate error: $e');
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<FormTemplate?> getTemplateById(String id) => getTemplate(id);

  @override
  Future<void> saveTemplate(FormTemplate template) async {
    _ensureInitialized();
    await _templateStoreRef.record(template.id).put(_db, template.toJson());
  }

  @override
  Future<void> deleteTemplate(String id, {bool softDelete = true}) async {
    _ensureInitialized();
    if (softDelete) {
      final existing = await getTemplate(id);
      if (existing != null) {
        final updated = existing.copyWith(deletedAt: DateTime.now());
        await saveTemplate(updated);
        return;
      }
    }
    await _templateStoreRef.record(id).delete(_db);
  }

  @override
  Future<List<FormSubmission>> getSubmissions({bool includeArchived = false}) async {
    _ensureInitialized();
    try {
      final records = await _submissionStoreRef.find(
        _db,
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
      return records.map((record) => FormSubmission.fromJson(record.value)).toList();
    } catch (e) {
      if (kIsWeb) {
        debugPrint('[PersistentStorageService] Web getSubmissions error: $e');
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<FormSubmission?> getSubmission(String id) async {
    _ensureInitialized();
    final data = await _submissionStoreRef.record(id).get(_db);
    if (data == null) return null;
    return FormSubmission.fromJson(data);
  }

  @override
  Future<FormSubmission?> getSubmissionById(String id) => getSubmission(id);

  @override
  Future<void> saveSubmission(FormSubmission submission) async {
    _ensureInitialized();
    await _submissionStoreRef.record(submission.id).put(_db, submission.toJson());
  }

  @override
  Future<void> deleteSubmission(String id, {bool softDelete = true}) async {
    _ensureInitialized();
    if (softDelete) {
      final existing = await getSubmission(id);
      if (existing != null) {
        final updated = existing.copyWith(deletedAt: DateTime.now());
        await saveSubmission(updated);
        return;
      }
    }
    await _submissionStoreRef.record(id).delete(_db);
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
    _ensureInitialized();
    try {
      final records = await _submissionStoreRef.find(
        _db,
        finder: Finder(
          filter: Filter.custom((record) {
            final data = record.value as Map<String, dynamic>;
            if (data['deletedAt'] != null) return false;
            if (data['formId'] != formId && data['templateId'] != formId) {
              return false;
            }
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
      return records.map((r) => FormSubmission.fromJson(r.value)).toList();
    } catch (e) {
      if (kIsWeb) {
        debugPrint('[PersistentStorageService] Web querySubmissions error: $e');
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<void> queueOutboxMutation(OutboxMutation mutation) async {
    _ensureInitialized();
    await _outboxStoreRef.record(mutation.id).put(_db, mutation.toMap());
  }

  @override
  Future<List<OutboxMutation>> getPendingOutboxMutations() async {
    _ensureInitialized();
    final records = await _outboxStoreRef.find(
      _db,
      finder: Finder(
        filter: Filter.isNull('syncedAt'),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    return records.map((r) => OutboxMutation.fromMap(r.value)).toList();
  }

  @override
  Future<void> markOutboxMutationsSynced(List<String> mutationIds) async {
    _ensureInitialized();
    final nowIso = DateTime.now().toIso8601String();
    for (final id in mutationIds) {
      final existing = await _outboxStoreRef.record(id).get(_db);
      if (existing != null) {
        final updated = Map<String, dynamic>.from(existing);
        updated['syncedAt'] = nowIso;
        await _outboxStoreRef.record(id).put(_db, updated);
      }
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Storage adapter must be initialized before performing operations.');
    }
  }
}
