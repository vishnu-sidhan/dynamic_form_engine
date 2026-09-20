import '../core/models/form_field_definition.dart';
import '../core/models/form_enums.dart';

/// Pure validation and conditional rule evaluation engine.
class FieldValidator {
  const FieldValidator._();

  /// Validates a single field answer value against all configured constraints.
  /// Returns an error message string or `null` if valid.
  static String? validate(FormFieldDefinition field, dynamic value) {
    final strVal = value?.toString().trim() ?? '';

    // 1. Required constraint check
    if (field.isRequired && strVal.isEmpty) {
      return field.customErrorMessage ?? 'This field is required';
    }

    // If empty and not required, constraint rules (min/max/regex) don't trigger
    if (strVal.isEmpty) return null;

    final rules = field.validationRules;

    // 2. Field type specific constraints
    switch (field.fieldType) {
      case FormFieldType.number:
      case FormFieldType.decimal:
      case FormFieldType.currency:
        final numVal = num.tryParse(strVal);
        if (numVal == null) {
          return field.customErrorMessage ?? 'Please enter a valid number';
        }
        final minVal = field.min ?? (rules['min'] as num?);
        if (minVal != null && numVal < minVal) {
          return field.customErrorMessage ?? 'Minimum value is $minVal';
        }
        final maxVal = field.max ?? (rules['max'] as num?);
        if (maxVal != null && numVal > maxVal) {
          return field.customErrorMessage ?? 'Maximum value is $maxVal';
        }
        break;

      case FormFieldType.email:
        final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
        if (!emailRegex.hasMatch(strVal)) {
          return field.customErrorMessage ?? 'Please enter a valid email address';
        }
        break;

      case FormFieldType.phone:
        final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
        if (!phoneRegex.hasMatch(strVal)) {
          return field.customErrorMessage ?? 'Please enter a valid phone number';
        }
        break;

      case FormFieldType.text:
      case FormFieldType.textarea:
        final minLength = (rules['minLength'] as num?)?.toInt();
        if (minLength != null && strVal.length < minLength) {
          return field.customErrorMessage ??
              'Minimum length is $minLength characters';
        }
        final maxLength = (rules['maxLength'] as num?)?.toInt();
        if (maxLength != null && strVal.length > maxLength) {
          return field.customErrorMessage ??
              'Maximum length is $maxLength characters';
        }
        break;

      default:
        break;
    }

    // 3. Regex validation check
    final regexPattern = field.validationRegex ?? rules['validationRegex']?.toString();
    if (regexPattern != null && regexPattern.isNotEmpty) {
      try {
        final regex = RegExp(regexPattern);
        if (!regex.hasMatch(strVal)) {
          return field.customErrorMessage ?? 'Invalid format';
        }
      } catch (_) {
        // Ignore invalid regex patterns
      }
    }

    return null;
  }

  /// Determines whether a field should be visible based on conditional dependency rules.
  static bool shouldShowField({
    required FormFieldDefinition field,
    required Map<String, dynamic> currentAnswers,
    required List<FormFieldDefinition> allFields,
  }) {
    // 1. Identify parent field key
    final dependsOn = field.dependsOnFieldKey ??
        field.validationRules['dependsOnKey']?.toString() ??
        field.validationRules['dependsOnLabel']?.toString();

    if (dependsOn == null || dependsOn.trim().isEmpty) {
      return true; // No dependency, always visible
    }

    final showIf = (field.showIfValue ??
            field.validationRules['showIf']?.toString() ??
            '*')
        .trim()
        .toLowerCase();

    // 2. Locate parent field in definitions
    FormFieldDefinition? parentField;
    final targetToken = dependsOn.trim().toLowerCase();
    for (final f in allFields) {
      if (f.id == dependsOn ||
          f.key == dependsOn ||
          f.label.trim().toLowerCase() == targetToken) {
        parentField = f;
        break;
      }
    }

    if (parentField == null) return false;

    // 3. Fetch parent field's current answer
    final rawParentVal = currentAnswers[parentField.id] ??
        currentAnswers[parentField.key] ??
        currentAnswers[parentField.effectiveKey];
    final parentValue = rawParentVal?.toString().trim().toLowerCase() ?? '';

    // 4. Wildcard matching: show if parent is filled/non-empty
    if (showIf == '*' ||
        showIf == 'set' ||
        showIf == 'filled' ||
        showIf == 'not_empty') {
      return parentValue.isNotEmpty;
    }

    // 5. Handle parent checkbox field
    final isParentChecked = parentValue == 'true' ||
        parentValue == 'yes' ||
        parentValue == '1' ||
        parentValue == 'checked';

    // 6. Split comma-separated expected values
    final allowedValues = showIf
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (final allowed in allowedValues) {
      if (parentField.fieldType == FormFieldType.checkbox) {
        final isAllowedTrue = allowed == 'yes' ||
            allowed == 'true' ||
            allowed == '1' ||
            allowed == 'checked';
        final isAllowedFalse = allowed == 'no' ||
            allowed == 'false' ||
            allowed == '0' ||
            allowed == 'unchecked';

        if (isParentChecked && isAllowedTrue) return true;
        if (!isParentChecked && isAllowedFalse) return true;
      }

      if (parentValue == allowed) return true;

      // Check multi-select list contains
      final parentList = parentValue
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      if (parentList.contains(allowed)) return true;
    }

    return false;
  }
}
