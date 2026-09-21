import '../models/form_template.dart';
import '../models/form_submission.dart';
import '../models/outbox_mutation.dart';

/// Database-agnostic Service Provider Interface (SPI) for form persistence.
/// Enables SQLite, Drift, PostgreSQL, Sembast, Hive, or Cloud Firestore integration.
abstract class FormStorageAdapter {
  /// Initializes underlying database or storage engine.
  Future<void> initialize();

  // ---------------------------------------------------------------------------
  // Template Operations
  // ---------------------------------------------------------------------------
  Future<void> saveTemplate(FormTemplate template);
  Future<FormTemplate?> getTemplateById(String id);
  Future<List<FormTemplate>> getTemplates({
    String? contextScope,
    bool includeArchived = false,
  });
  Future<void> deleteTemplate(String id, {bool softDelete = true});

  // ---------------------------------------------------------------------------
  // Submission Operations
  // ---------------------------------------------------------------------------
  Future<void> saveSubmission(FormSubmission submission);
  Future<FormSubmission?> getSubmissionById(String id);
  Future<List<FormSubmission>> getSubmissions({bool includeArchived = false});
  Future<List<FormSubmission>> querySubmissions({
    required String formId,
    String? contextId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });
  Future<void> deleteSubmission(String id, {bool softDelete = true});

  // ---------------------------------------------------------------------------
  // Transactional Outbox (Offline-First Sync Queue)
  // ---------------------------------------------------------------------------
  Future<void> queueOutboxMutation(OutboxMutation mutation);
  Future<List<OutboxMutation>> getPendingOutboxMutations();
  Future<void> markOutboxMutationsSynced(List<String> mutationIds);
}
