import '../models/form_template.dart';
import '../models/outbox_mutation.dart';

/// Contract for bidirectional remote synchronization (e.g. Supabase / REST / Notion API).
abstract class FormSyncDelegate {
  /// Pushes local transactional outbox mutations to the remote backend.
  Future<void> pushMutations(List<OutboxMutation> mutations);

  /// Pulls updated form templates from the remote backend created/updated after [lastSyncedAt].
  Future<List<FormTemplate>> pullTemplates(DateTime? lastSyncedAt);
}
