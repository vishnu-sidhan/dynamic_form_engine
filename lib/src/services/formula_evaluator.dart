import 'dart:convert';
import '../core/models/form_field_definition.dart';
import '../core/models/form_enums.dart';

/// Pure calculation engine for dynamically computed fields.
/// Supports both tokenized expressions (e.g. `[qty] * [unit_cost]`) and structured JSON formulas.
class FormulaEvaluator {
  const FormulaEvaluator._();

  /// Evaluates a formula string (token expression or JSON) against current form answers.
  static String evaluate({
    String? formula,
    String? formulaConfigJson,
    dynamic allFields,
    required Map<String, dynamic> currentAnswers,
  }) {
    final effectiveFormula = formula ?? formulaConfigJson ?? '';
    if (effectiveFormula.trim().isEmpty) return '';

    List<FormFieldDefinition> fields = [];
    if (allFields is List<FormFieldDefinition>) {
      fields = allFields;
    } else if (allFields is List) {
      for (final f in allFields) {
        if (f is FormFieldDefinition) {
          fields.add(f);
        } else {
          try {
            final id = (f as dynamic).id?.toString() ?? '';
            final label = (f as dynamic).label?.toString() ?? '';
            fields.add(FormFieldDefinition(
              id: id,
              formId: '',
              key: label,
              label: label,
              fieldType: FormFieldType.text,
            ));
          } catch (_) {}
        }
      }
    }

    // Check if formula is a JSON-encoded configuration
    if (effectiveFormula.trim().startsWith('{')) {
      return _evaluateJsonFormula(
        formulaJson: effectiveFormula,
        allFields: fields,
        currentAnswers: currentAnswers,
      );
    }

    // Otherwise evaluate as tokenized arithmetic expression
    return _evaluateTokenExpression(
      expression: effectiveFormula,
      allFields: fields,
      currentAnswers: currentAnswers,
    );
  }

  /// Evaluates structured JSON formula (legacy format)
  /// e.g. `{"formula": {"type": "add|subtract|multiply|divide", "operands": ["A", "B"], "precision": 2}}`
  static String _evaluateJsonFormula({
    required String formulaJson,
    required List<FormFieldDefinition> allFields,
    required Map<String, dynamic> currentAnswers,
  }) {
    try {
      final decoded = jsonDecode(formulaJson);
      if (decoded is! Map<String, dynamic>) return '';

      final formulaMap = decoded['formula'] is Map<String, dynamic>
          ? decoded['formula'] as Map<String, dynamic>
          : decoded;

      final type = formulaMap['type']?.toString().toLowerCase();
      final operandsList = formulaMap['operands'];
      final precision = (formulaMap['precision'] as num?)?.toInt() ?? 2;

      if (type == null || operandsList is! List || operandsList.isEmpty) {
        return '';
      }

      final List<double> values = [];
      for (final op in operandsList) {
        final operandToken = op.toString().trim();
        final field = _findField(operandToken, allFields);
        if (field == null) return '';

        final answer = _resolveFieldValue(field, currentAnswers);
        if (answer == null) return '';

        final parsed = double.tryParse(answer.toString().trim());
        if (parsed == null) return '';
        values.add(parsed);
      }

      if (values.isEmpty) return '';
      if (values.length == 1) return values.first.toStringAsFixed(precision);

      double result = values.first;
      for (int i = 1; i < values.length; i++) {
        final val = values[i];
        if (type == 'add') {
          result += val;
        } else if (type == 'subtract') {
          result -= val;
        } else if (type == 'multiply') {
          result *= val;
        } else if (type == 'divide') {
          if (val == 0.0) {
            // Division by zero safety: resolve to 0.0 with precision
            return (0.0).toStringAsFixed(precision);
          }
          result /= val;
        } else {
          return '';
        }
      }

      return result.toStringAsFixed(precision);
    } catch (_) {
      return '';
    }
  }

  /// Evaluates token expression: e.g. `[field_a] * [field_b] + 10`
  static String _evaluateTokenExpression({
    required String expression,
    required List<FormFieldDefinition> allFields,
    required Map<String, dynamic> currentAnswers,
    int precision = 2,
  }) {
    try {
      final tokenRegex = RegExp(r'\[([^\]]+)\]');
      String substituted = expression;

      final matches = tokenRegex.allMatches(expression);
      for (final match in matches) {
        final tokenName = match.group(1)!.trim();
        final field = _findField(tokenName, allFields);
        if (field == null) return '';

        final answer = _resolveFieldValue(field, currentAnswers);
        if (answer == null) return '';

        final parsed = double.tryParse(answer.toString().trim());
        if (parsed == null) return '';

        substituted = substituted.replaceAll(match.group(0)!, parsed.toString());
      }

      // Simple token evaluation for standard binary operations
      final trimmed = substituted.replaceAll(' ', '');
      final res = _simpleEvaluateArithmetic(trimmed);
      if (res == null) return '';
      return res.toStringAsFixed(precision);
    } catch (_) {
      return '';
    }
  }

  /// Helper to locate field by id, key, or case-insensitive label
  static FormFieldDefinition? _findField(
    String token,
    List<FormFieldDefinition> allFields,
  ) {
    final lower = token.trim().toLowerCase();
    for (final field in allFields) {
      if (field.id == token ||
          field.key == token ||
          field.label.trim().toLowerCase() == lower) {
        return field;
      }
    }
    return null;
  }

  /// Helper to extract value from answers map checking id, key, and effectiveKey
  static dynamic _resolveFieldValue(
    FormFieldDefinition field,
    Map<String, dynamic> answers,
  ) {
    if (answers.containsKey(field.id) && answers[field.id] != null) {
      return answers[field.id];
    }
    if (answers.containsKey(field.key) && answers[field.key] != null) {
      return answers[field.key];
    }
    if (answers.containsKey(field.effectiveKey) &&
        answers[field.effectiveKey] != null) {
      return answers[field.effectiveKey];
    }
    return null;
  }

  /// Lightweight parser for basic arithmetic expressions (+, -, *, /)
  static double? _simpleEvaluateArithmetic(String expr) {
    if (expr.isEmpty) return null;

    // Handle addition and subtraction (lowest precedence)
    int depth = 0;
    for (int i = expr.length - 1; i >= 0; i--) {
      final char = expr[i];
      if (char == ')') depth++;
      if (char == '(') depth--;
      if (depth == 0 && (char == '+' || (char == '-' && i > 0))) {
        final left = _simpleEvaluateArithmetic(expr.substring(0, i));
        final right = _simpleEvaluateArithmetic(expr.substring(i + 1));
        if (left == null || right == null) return null;
        return char == '+' ? left + right : left - right;
      }
    }

    // Handle multiplication and division
    depth = 0;
    for (int i = expr.length - 1; i >= 0; i--) {
      final char = expr[i];
      if (char == ')') depth++;
      if (char == '(') depth--;
      if (depth == 0 && (char == '*' || char == '/')) {
        final left = _simpleEvaluateArithmetic(expr.substring(0, i));
        final right = _simpleEvaluateArithmetic(expr.substring(i + 1));
        if (left == null || right == null) return null;
        if (char == '/') {
          if (right == 0.0) return 0.0; // Safe division by zero
          return left / right;
        }
        return left * right;
      }
    }

    // Remove surrounding parentheses
    if (expr.startsWith('(') && expr.endsWith(')')) {
      return _simpleEvaluateArithmetic(expr.substring(1, expr.length - 1));
    }

    return double.tryParse(expr);
  }
}
