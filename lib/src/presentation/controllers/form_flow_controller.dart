import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/form_template.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_submission.dart';
import '../../core/models/form_enums.dart';
import '../../core/contracts/form_storage_adapter.dart';
import '../../core/contracts/form_option_resolver.dart';
import '../../core/contracts/form_submission_interceptor.dart';
import '../../services/formula_evaluator.dart';
import '../../services/field_validator.dart';

/// Pure Dart state controller managing dynamic form execution, answer states,
/// live sequential recalculations, field visibility, validation, and submission lifecycle.
class FormFlowController extends ChangeNotifier {
  final FormTemplate template;
  final FormStorageAdapter? storageAdapter;
  final FormOptionResolver optionResolver;
  final List<FormSubmissionInterceptor> interceptors;

  Map<String, dynamic> _answers = {};
  Map<String, String> _errors = {};
  final Set<String> _prefilledKeys = {};
  bool _isDirty = false;
  bool _isSubmitting = false;
  bool _readOnly = false;

  FormFlowController({
    required this.template,
    this.storageAdapter,
    this.optionResolver = const DefaultFormOptionResolver(),
    this.interceptors = const [],
    Map<String, dynamic> initialAnswers = const {},
    bool readOnly = false,
  }) : _readOnly = readOnly {
    if (initialAnswers.isNotEmpty) {
      setAnswers(initialAnswers, isPrefill: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  Map<String, dynamic> get answers => Map.unmodifiable(_answers);
  Map<String, String> get errors => Map.unmodifiable(_errors);
  Set<String> get prefilledKeys => Set.unmodifiable(_prefilledKeys);
  bool get isDirty => _isDirty;
  bool get isSubmitting => _isSubmitting;
  bool get readOnly => _readOnly;
  List<FormFieldDefinition> get fields => template.fields;

  void setReadOnly(bool value) {
    if (_readOnly != value) {
      _readOnly = value;
      notifyListeners();
    }
  }

  dynamic getAnswer(String keyOrId) {
    return _answers[keyOrId];
  }

  String? getError(String keyOrId) {
    return _errors[keyOrId];
  }

  bool isFieldVisible(FormFieldDefinition field) {
    return FieldValidator.shouldShowField(
      field: field,
      currentAnswers: _answers,
      allFields: fields,
    );
  }

  // ---------------------------------------------------------------------------
  // Answer Mutation & Live Recalculations
  // ---------------------------------------------------------------------------

  void updateAnswer(String keyOrId, dynamic value) {
    _answers[keyOrId] = value;
    _isDirty = true;
    _clearFieldError(keyOrId);
    notifyListeners();
  }

  void updateAnswerAndRecalculate(String keyOrId, dynamic value) {
    _answers[keyOrId] = value;
    _isDirty = true;
    _clearFieldError(keyOrId);

    // Sequential evaluation of calculated fields to prevent recursive loops
    final updatedMap = Map<String, dynamic>.from(_answers);
    for (final field in fields) {
      if (field.fieldType == FormFieldType.calculated) {
        final formula = field.calculationFormula ??
            field.validationRules['formula']?.toString();
        if (formula != null && formula.isNotEmpty) {
          final computed = FormulaEvaluator.evaluate(
            formula: formula,
            allFields: fields,
            currentAnswers: updatedMap,
          );
          updatedMap[field.id] = computed;
          updatedMap[field.key] = computed;
        }
      }
    }

    _answers = updatedMap;
    notifyListeners();
  }

  void setAnswers(Map<String, dynamic> newAnswers, {bool isPrefill = false}) {
    _answers = Map<String, dynamic>.from(newAnswers);
    if (isPrefill) {
      _prefilledKeys.addAll(newAnswers.keys);
    }
    // Re-evaluate calculated fields once after setting initial answers
    final updatedMap = Map<String, dynamic>.from(_answers);
    for (final field in fields) {
      if (field.fieldType == FormFieldType.calculated) {
        final formula = field.calculationFormula ??
            field.validationRules['formula']?.toString();
        if (formula != null && formula.isNotEmpty) {
          final computed = FormulaEvaluator.evaluate(
            formula: formula,
            allFields: fields,
            currentAnswers: updatedMap,
          );
          updatedMap[field.id] = computed;
          updatedMap[field.key] = computed;
        }
      }
    }
    _answers = updatedMap;
    _errors.clear();
    notifyListeners();
  }

  void _clearFieldError(String keyOrId) {
    if (_errors.containsKey(keyOrId)) {
      final newErrors = Map<String, String>.from(_errors);
      newErrors.remove(keyOrId);
      _errors = newErrors;
    }
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool validate() {
    final newErrors = <String, String>{};

    for (final field in fields) {
      // If conditional logic hides the field, skip validation
      if (!isFieldVisible(field)) continue;

      final val = _answers[field.id] ?? _answers[field.key];
      final error = FieldValidator.validate(field, val);
      if (error != null) {
        newErrors[field.id] = error;
        newErrors[field.key] = error;
      }
    }

    _errors = newErrors;
    notifyListeners();
    return newErrors.isEmpty;
  }

  // ---------------------------------------------------------------------------
  // Submission Pipeline
  // ---------------------------------------------------------------------------

  Future<FormSubmission?> submit({
    String? submissionId,
    String? submittedByUserId,
    String? contextType,
    String? contextId,
    Map<String, dynamic> extraMetadata = const {},
  }) async {
    if (!validate()) {
      return null;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final subId = submissionId ?? const Uuid().v4();
      final submission = FormSubmission(
        id: subId,
        formId: template.id,
        contextType: contextType ?? template.contextScope,
        contextId: contextId,
        submittedByUserId: submittedByUserId,
        submittedAt: DateTime.now(),
        answers: Map<String, dynamic>.from(_answers),
        status: SubmissionStatus.submitted,
        metadata: extraMetadata,
      );

      // 1. Interceptors: onBeforeSubmit
      for (final interceptor in interceptors) {
        await interceptor.onBeforeSubmit(submission);
      }

      // 2. Storage persistence
      if (storageAdapter != null) {
        await storageAdapter!.saveSubmission(submission);
      }

      // 3. Interceptors: onAfterSubmit
      for (final interceptor in interceptors) {
        await interceptor.onAfterSubmit(submission);
      }

      _isDirty = false;
      return submission;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clear() {
    _answers.clear();
    _errors.clear();
    _prefilledKeys.clear();
    _isDirty = false;
    _isSubmitting = false;
    notifyListeners();
  }
}
