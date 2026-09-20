import '../models/form_field_definition.dart';

/// Contract for resolving relational options from external data sources or local databases.
abstract class FormOptionResolver {
  /// Resolves selectable options for a given [referenceTarget] (e.g., 'categories', 'departments', 'users').
  Future<List<FormOption>> resolveOptions({
    required String referenceTarget,
    String? contextId,
    Map<String, dynamic>? metadata,
  });

  /// Resolves a single raw ID or foreign key value to its human-readable display label.
  Future<String> resolveDisplayValue({
    required String referenceTarget,
    required String rawValue,
    String? contextId,
  }) async {
    final options = await resolveOptions(
      referenceTarget: referenceTarget,
      contextId: contextId,
    );
    for (final opt in options) {
      if (opt.value == rawValue) return opt.label;
    }
    return rawValue;
  }
}

/// Fallback default resolver when no custom resolver is configured.
class DefaultFormOptionResolver implements FormOptionResolver {
  const DefaultFormOptionResolver();

  @override
  Future<List<FormOption>> resolveOptions({
    required String referenceTarget,
    String? contextId,
    Map<String, dynamic>? metadata,
  }) async {
    return const [];
  }

  @override
  Future<String> resolveDisplayValue({
    required String referenceTarget,
    required String rawValue,
    String? contextId,
  }) async {
    return rawValue;
  }
}
