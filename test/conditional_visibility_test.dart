import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

void main() {
  group('Conditional Visibility', () {
    const parentField = FormFieldDefinition(
      id: 'f_parent',
      formId: 'form-1',
      key: 'has_discount',
      label: 'Apply Discount Coupon?',
      fieldType: FormFieldType.checkbox,
    );

    const childField = FormFieldDefinition(
      id: 'f_child',
      formId: 'form-1',
      key: 'discount_code',
      label: 'Coupon Code',
      fieldType: FormFieldType.text,
      dependsOnFieldKey: 'has_discount',
      showIfValue: 'true',
    );

    final allFields = [parentField, childField];

    test('shows dependent field only when parent checkbox matches "true"', () {
      final answersFalse = {'f_parent': 'false'};
      expect(
        FieldValidator.shouldShowField(
          field: childField,
          currentAnswers: answersFalse,
          allFields: allFields,
        ),
        isFalse,
      );

      final answersTrue = {'f_parent': 'true'};
      expect(
        FieldValidator.shouldShowField(
          field: childField,
          currentAnswers: answersTrue,
          allFields: allFields,
        ),
        isTrue,
      );
    });

    test('supports wildcard "*" for any non-empty answer', () {
      const wildcardChild = FormFieldDefinition(
        id: 'f_wild',
        formId: 'form-1',
        key: 'discount_notes',
        label: 'Discount Notes',
        fieldType: FormFieldType.text,
        dependsOnFieldKey: 'f_parent',
        showIfValue: '*',
      );

      expect(
        FieldValidator.shouldShowField(
          field: wildcardChild,
          currentAnswers: {'f_parent': ''},
          allFields: allFields,
        ),
        isFalse,
      );

      expect(
        FieldValidator.shouldShowField(
          field: wildcardChild,
          currentAnswers: {'f_parent': 'yes'},
          allFields: allFields,
        ),
        isTrue,
      );
    });

    test('supports comma-separated values with case-insensitivity', () {
      const dropdownParent = FormFieldDefinition(
        id: 'f_status',
        formId: 'form-1',
        key: 'status',
        label: 'Status',
        fieldType: FormFieldType.dropdown,
      );

      const statusChild = FormFieldDefinition(
        id: 'f_details',
        formId: 'form-1',
        key: 'details',
        label: 'Details',
        fieldType: FormFieldType.text,
        dependsOnFieldKey: 'status',
        showIfValue: 'failed,rejected,cancelled',
      );

      final fields = [dropdownParent, statusChild];

      expect(
        FieldValidator.shouldShowField(
          field: statusChild,
          currentAnswers: {'status': 'Approved'},
          allFields: fields,
        ),
        isFalse,
      );

      expect(
        FieldValidator.shouldShowField(
          field: statusChild,
          currentAnswers: {'status': 'Rejected'},
          allFields: fields,
        ),
        isTrue,
      );
    });
  });
}
