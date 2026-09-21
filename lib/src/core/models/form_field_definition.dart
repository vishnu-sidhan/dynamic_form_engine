import 'dart:convert';
import 'form_enums.dart';

/// Single selectable option for dropdowns, radios, and multi-select fields.
class FormOption {
  final String label;
  final String value;
  final Map<String, dynamic> metadata;

  const FormOption({
    required this.label,
    required this.value,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
      'metadata': metadata,
    };
  }

  factory FormOption.fromMap(Map<String, dynamic> map) {
    return FormOption(
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
      metadata: map['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  factory FormOption.fromRaw(dynamic raw) {
    if (raw is FormOption) return raw;
    if (raw is Map<String, dynamic>) return FormOption.fromMap(raw);
    if (raw is Map) return FormOption.fromMap(Map<String, dynamic>.from(raw));
    final str = raw?.toString() ?? '';
    return FormOption(label: str, value: str);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormOption &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;

  @override
  String toString() => 'FormOption(label: $label, value: $value)';
}

/// Canonical pure Dart definition for a dynamic form field.
class FormFieldDefinition {
  // Identity & Basics
  final String id;
  final String formId;
  final String key;
  final String label;
  final String? hint;
  final int orderIndex;
  final FormFieldType fieldType;

  // Constraints
  final bool isRequired;
  final bool isReadOnly;
  final num? min;
  final num? max;
  final String? validationRegex;
  final String? customErrorMessage;

  // Dynamic Rules
  final String? dependsOnFieldKey;
  final String? showIfValue;
  final Map<String, dynamic> validationRules;

  // Configurations
  final List<FormOption> options;
  final String? referenceTarget;
  final String? calculationFormula;
  final Map<String, dynamic> metadata;

  const FormFieldDefinition({
    required this.id,
    String? formId,
    String? key,
    required this.label,
    this.hint,
    this.orderIndex = 0,
    FormFieldType? fieldType,
    FormFieldType? type,
    this.isRequired = false,
    this.isReadOnly = false,
    this.min,
    this.max,
    this.validationRegex,
    this.customErrorMessage,
    this.dependsOnFieldKey,
    this.showIfValue,
    this.validationRules = const {},
    this.options = const [],
    this.referenceTarget,
    this.calculationFormula,
    this.metadata = const {},
  })  : formId = formId ?? '',
        key = (key != null && key != '') ? key : id,
        fieldType = fieldType ?? type ?? FormFieldType.text;

  /// Alias for [fieldType]
  FormFieldType get type => fieldType;

  /// The effective field key used for mapping answers (defaults to [key], fallback [id]).
  String get effectiveKey => key.isNotEmpty ? key : id;

  FormFieldDefinition copyWith({
    String? id,
    String? formId,
    String? key,
    String? label,
    String? hint,
    int? orderIndex,
    FormFieldType? fieldType,
    FormFieldType? type,
    bool? isRequired,
    bool? isReadOnly,
    num? min,
    num? max,
    String? validationRegex,
    String? customErrorMessage,
    String? dependsOnFieldKey,
    String? showIfValue,
    Map<String, dynamic>? validationRules,
    List<FormOption>? options,
    String? referenceTarget,
    String? calculationFormula,
    Map<String, dynamic>? metadata,
  }) {
    return FormFieldDefinition(
      id: id ?? this.id,
      formId: formId ?? this.formId,
      key: key ?? this.key,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      orderIndex: orderIndex ?? this.orderIndex,
      fieldType: fieldType ?? type ?? this.fieldType,
      isRequired: isRequired ?? this.isRequired,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      min: min ?? this.min,
      max: max ?? this.max,
      validationRegex: validationRegex ?? this.validationRegex,
      customErrorMessage: customErrorMessage ?? this.customErrorMessage,
      dependsOnFieldKey: dependsOnFieldKey ?? this.dependsOnFieldKey,
      showIfValue: showIfValue ?? this.showIfValue,
      validationRules: validationRules ?? this.validationRules,
      options: options ?? this.options,
      referenceTarget: referenceTarget ?? this.referenceTarget,
      calculationFormula: calculationFormula ?? this.calculationFormula,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'formId': formId,
      'key': key,
      'label': label,
      'hint': hint,
      'orderIndex': orderIndex,
      'fieldType': fieldType.name,
      'type': fieldType.name,
      'isRequired': isRequired,
      'isReadOnly': isReadOnly,
      'min': min,
      'max': max,
      'validationRegex': validationRegex,
      'customErrorMessage': customErrorMessage,
      'dependsOnFieldKey': dependsOnFieldKey,
      'showIfValue': showIfValue,
      'validationRules': validationRules,
      'options': options.map((o) => o.toMap()).toList(),
      'referenceTarget': referenceTarget,
      'calculationFormula': calculationFormula,
      'metadata': metadata,
    };
  }

  factory FormFieldDefinition.fromMap(Map<String, dynamic> map) {
    // Parse options: can be list of FormOption, maps, strings, or JSON-encoded string
    List<FormOption> parsedOptions = [];
    final rawOptions = map['options'] ?? map['optionsData'];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => FormOption.fromRaw(e)).toList();
    } else if (rawOptions is String && rawOptions.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawOptions);
        if (decoded is List) {
          parsedOptions = decoded.map((e) => FormOption.fromRaw(e)).toList();
        }
      } catch (_) {
        // Fallback comma-separated
        parsedOptions = rawOptions
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map((s) => FormOption(label: s, value: s))
            .toList();
      }
    }

    // Parse validation rules
    Map<String, dynamic> rules = {};
    final rawRules = map['validationRules'];
    if (rawRules is Map<String, dynamic>) {
      rules = Map<String, dynamic>.from(rawRules);
    } else if (rawRules is String && rawRules.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawRules);
        if (decoded is Map<String, dynamic>) {
          rules = decoded;
        }
      } catch (_) {}
    }

    // Extract dynamic rules if embedded in validationRules
    final dependsOn = map['dependsOnFieldKey']?.toString() ??
        rules['dependsOnKey']?.toString() ??
        rules['dependsOnLabel']?.toString();
    final showIf =
        map['showIfValue']?.toString() ?? rules['showIf']?.toString();

    // Field type extraction
    final rawType =
        map['fieldType']?.toString() ?? map['type']?.toString() ?? 'text';
    final fieldType = FormFieldType.fromString(rawType);

    // Calculation formula extraction (can be in validationRules or dedicated field)
    String? formula = map['calculationFormula']?.toString();
    if (formula == null && rules.containsKey('formula')) {
      formula = jsonEncode(rules['formula']);
    }

    return FormFieldDefinition(
      id: map['id']?.toString() ?? '',
      formId: map['formId']?.toString() ?? '',
      key: map['key']?.toString() ?? map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      hint: map['hint']?.toString(),
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      fieldType: fieldType,
      isRequired: map['isRequired'] == true || map['isRequired'] == 1,
      isReadOnly: map['isReadOnly'] == true || map['isReadOnly'] == 1,
      min: map['min'] as num? ?? (rules['min'] as num?),
      max: map['max'] as num? ?? (rules['max'] as num?),
      validationRegex: map['validationRegex']?.toString() ??
          rules['validationRegex']?.toString(),
      customErrorMessage: map['customErrorMessage']?.toString() ??
          rules['customErrorMessage']?.toString(),
      dependsOnFieldKey: dependsOn,
      showIfValue: showIf,
      validationRules: rules,
      options: parsedOptions,
      referenceTarget: map['referenceTarget']?.toString(),
      calculationFormula: formula,
      metadata: map['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }
}
