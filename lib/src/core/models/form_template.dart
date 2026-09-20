import 'form_field_definition.dart';
import 'form_enums.dart';

/// Canonical pure Dart document model representing a dynamic form template.
class FormTemplate {
  final String id;
  final String name;
  final String? description;
  final String? contextScope; // e.g. workspaceId, tenantId, organizationId, or 'global'
  final bool isSystemLocked;
  final int version;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<FormFieldDefinition> fields;

  const FormTemplate({
    required this.id,
    required this.name,
    this.description,
    this.contextScope,
    this.isSystemLocked = false,
    this.version = 1,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.fields = const [],
  });

  bool get isArchived => deletedAt != null;

  // Compatibility helpers
  bool get isSystemForm =>
      isSystemLocked || metadata['isSystemForm'] == true;
  bool get isActive => deletedAt == null && metadata['isActive'] != false;

  FormScope get formScope {
    final raw = metadata['formScope']?.toString();
    if (raw == 'GLOBAL_MANDATORY') return FormScope.GLOBAL_MANDATORY;
    if (raw == 'CONTEXT_SPECIFIC' || raw == 'FARM_SPECIFIC') {
      return FormScope.CONTEXT_SPECIFIC;
    }
    return FormScope.GLOBAL_OPTIONAL;
  }

  FormScopeType get scopeType {
    final raw = metadata['scopeType']?.toString();
    if (raw == 'contextRequired' || raw == 'farmRequired') {
      return FormScopeType.contextRequired;
    }
    if (raw == 'contextOptional' || raw == 'farmOptional') {
      return FormScopeType.contextOptional;
    }
    return FormScopeType.global;
  }

  FormTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? contextScope,
    bool? isSystemLocked,
    int? version,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<FormFieldDefinition>? fields,
  }) {
    return FormTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contextScope: contextScope ?? this.contextScope,
      isSystemLocked: isSystemLocked ?? this.isSystemLocked,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contextScope': contextScope,
      'isSystemLocked': isSystemLocked,
      'version': version,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'fields': fields.map((f) => f.toMap()).toList(),
    };
  }

  factory FormTemplate.fromMap(Map<String, dynamic> map) {
    List<FormFieldDefinition> parsedFields = [];
    if (map['fields'] is List) {
      parsedFields = (map['fields'] as List)
          .whereType<Map<String, dynamic>>()
          .map((f) => FormFieldDefinition.fromMap(f))
          .toList();
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is DateTime) {
        parsedCreatedAt = map['createdAt'] as DateTime;
      } else {
        parsedCreatedAt =
            DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
      }
    }

    DateTime? parsedUpdatedAt;
    if (map['updatedAt'] != null) {
      if (map['updatedAt'] is DateTime) {
        parsedUpdatedAt = map['updatedAt'] as DateTime;
      } else {
        parsedUpdatedAt = DateTime.tryParse(map['updatedAt'].toString());
      }
    }

    DateTime? parsedDeletedAt;
    if (map['deletedAt'] != null) {
      if (map['deletedAt'] is DateTime) {
        parsedDeletedAt = map['deletedAt'] as DateTime;
      } else {
        parsedDeletedAt = DateTime.tryParse(map['deletedAt'].toString());
      }
    }

    return FormTemplate(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      contextScope: map['contextScope']?.toString() ?? map['farmId']?.toString(),
      isSystemLocked: map['isSystemLocked'] == true ||
          map['isSystemForm'] == true ||
          map['is_system_form'] == true,
      version: (map['version'] as num?)?.toInt() ?? 1,
      metadata: map['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : {
              if (map['formScope'] != null) 'formScope': map['formScope'],
              if (map['scopeType'] != null) 'scopeType': map['scopeType'],
            },
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      deletedAt: parsedDeletedAt,
      fields: parsedFields,
    );
  }
}
