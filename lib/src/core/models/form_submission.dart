import 'form_enums.dart';

/// Canonical pure Dart document model representing a filled dynamic form submission.
class FormSubmission {
  final String id;
  final String formId;
  String get templateId => formId;
  final String? contextType; // e.g. 'workspace', 'organization', 'tenant'
  final String? contextId; // Generic parent entity or scope ID
  final String? submittedByUserId;
  final DateTime submittedAt;
  final Map<String, dynamic> answers; // fieldId/key -> dynamic value
  final SubmissionStatus status;
  final DateTime? deletedAt;
  final Map<String, dynamic> metadata;

  const FormSubmission({
    required this.id,
    String? formId,
    String? templateId,
    this.contextType,
    this.contextId,
    this.submittedByUserId,
    required this.submittedAt,
    Map<String, dynamic>? data,
    Map<String, dynamic> answers = const {},
    this.status = SubmissionStatus.submitted,
    this.deletedAt,
    this.metadata = const {},
  })  : formId = formId ?? templateId ?? '',
        answers = data ?? answers;

  bool get isDeleted => deletedAt != null;

  // Convenient lookup helper for field key or id
  dynamic getAnswer(String key) => answers[key];

  /// Alias for answers for compatibility with external serializers
  Map<String, dynamic> get data => answers;

  FormSubmission copyWith({
    String? id,
    String? formId,
    String? templateId,
    String? contextType,
    String? contextId,
    String? submittedByUserId,
    DateTime? submittedAt,
    Map<String, dynamic>? answers,
    Map<String, dynamic>? data,
    SubmissionStatus? status,
    DateTime? deletedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FormSubmission(
      id: id ?? this.id,
      formId: formId ?? templateId ?? this.formId,
      templateId: templateId ?? formId ?? this.templateId,
      contextType: contextType ?? this.contextType,
      contextId: contextId ?? this.contextId,
      submittedByUserId: submittedByUserId ?? this.submittedByUserId,
      submittedAt: submittedAt ?? this.submittedAt,
      answers: answers ?? data ?? this.answers,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'formId': formId,
      'templateId': formId,
      'contextType': contextType,
      'contextId': contextId,
      'submittedByUserId': submittedByUserId,
      'submittedAt': submittedAt.toIso8601String(),
      'answers': answers,
      'data': answers,
      'status': status.name,
      'deletedAt': deletedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory FormSubmission.fromJson(Map<String, dynamic> json) =>
      FormSubmission.fromMap(json);

  factory FormSubmission.fromMap(Map<String, dynamic> map) {
    DateTime parsedSubmittedAt = DateTime.now();
    if (map['submittedAt'] != null) {
      if (map['submittedAt'] is DateTime) {
        parsedSubmittedAt = map['submittedAt'] as DateTime;
      } else {
        parsedSubmittedAt =
            DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now();
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

    SubmissionStatus parsedStatus = SubmissionStatus.submitted;
    if (map['status'] != null) {
      final s = map['status'].toString().toLowerCase();
      if (s == 'draft') parsedStatus = SubmissionStatus.draft;
      if (s == 'synced') parsedStatus = SubmissionStatus.synced;
    }

    Map<String, dynamic> parsedAnswers = {};
    if (map['answers'] is Map) {
      parsedAnswers = Map<String, dynamic>.from(map['answers'] as Map);
    } else if (map['data'] is Map) {
      parsedAnswers = Map<String, dynamic>.from(map['data'] as Map);
    }

    final resolvedFormId =
        map['formId']?.toString() ?? map['templateId']?.toString() ?? '';

    return FormSubmission(
      id: map['id']?.toString() ?? '',
      formId: resolvedFormId,
      templateId: resolvedFormId,
      contextType: map['contextType']?.toString(),
      contextId: map['contextId']?.toString() ?? map['farmId']?.toString(),
      submittedByUserId: map['submittedByUserId']?.toString(),
      submittedAt: parsedSubmittedAt,
      answers: parsedAnswers,
      status: parsedStatus,
      deletedAt: parsedDeletedAt,
      metadata: map['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormSubmission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          formId == other.formId &&
          contextType == other.contextType &&
          contextId == other.contextId &&
          status == other.status &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      formId.hashCode ^
      (contextId?.hashCode ?? 0) ^
      status.hashCode;
}
