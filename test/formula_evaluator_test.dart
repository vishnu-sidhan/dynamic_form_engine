import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

void main() {
  group('FormulaEvaluator', () {
    final fields = [
      const FormFieldDefinition(
        id: 'f1',
        formId: 'form-1',
        key: 'field_a',
        label: 'Field A',
        fieldType: FormFieldType.number,
      ),
      const FormFieldDefinition(
        id: 'f2',
        formId: 'form-1',
        key: 'field_b',
        label: 'Field B',
        fieldType: FormFieldType.number,
      ),
      const FormFieldDefinition(
        id: 'f3',
        formId: 'form-1',
        key: 'total',
        label: 'Total',
        fieldType: FormFieldType.calculated,
      ),
    ];

    test('evaluates token expression: [field_a] * [field_b]', () {
      final answers = {'f1': '15', 'f2': '4'};
      final result = FormulaEvaluator.evaluate(
        formula: '[field_a] * [field_b]',
        allFields: fields,
        currentAnswers: answers,
      );
      expect(result, '60.00');
    });

    test('evaluates legacy JSON formula configuration', () {
      const formulaJson =
          '{"formula":{"type":"add","operands":["Field A","Field B"],"precision":1}}';
      final answers = {'f1': '10', 'f2': '5'};
      final result = FormulaEvaluator.evaluate(
        formula: formulaJson,
        allFields: fields,
        currentAnswers: answers,
      );
      expect(result, '15.0');
    });

    test('handles division by zero safely without crashing', () {
      const formulaJson =
          '{"formula":{"type":"divide","operands":["Field A","Field B"],"precision":2}}';
      final answers = {'f1': '100', 'f2': '0'};
      final result = FormulaEvaluator.evaluate(
        formula: formulaJson,
        allFields: fields,
        currentAnswers: answers,
      );
      expect(result, '0.00');
    });

    test('returns empty string when operand is missing', () {
      final answers = {'f1': '10'};
      final result = FormulaEvaluator.evaluate(
        formula: '[field_a] * [field_b]',
        allFields: fields,
        currentAnswers: answers,
      );
      expect(result, '');
    });
  });
}
