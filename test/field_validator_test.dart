import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

void main() {
  group('FieldValidator', () {
    test('validates required fields correctly', () {
      const field = FormFieldDefinition(
        id: 'f1',
        formId: 'form-1',
        key: 'name',
        label: 'Name',
        fieldType: FormFieldType.text,
        isRequired: true,
        customErrorMessage: 'Name is mandatory',
      );

      expect(FieldValidator.validate(field, ''), 'Name is mandatory');
      expect(FieldValidator.validate(field, null), 'Name is mandatory');
      expect(FieldValidator.validate(field, 'John Doe'), isNull);
    });

    test('validates number min and max bounds', () {
      const field = FormFieldDefinition(
        id: 'f2',
        formId: 'form-1',
        key: 'age',
        label: 'Age',
        fieldType: FormFieldType.number,
        min: 18,
        max: 65,
      );

      expect(FieldValidator.validate(field, '15'), 'Minimum value is 18');
      expect(FieldValidator.validate(field, '70'), 'Maximum value is 65');
      expect(FieldValidator.validate(field, '25'), isNull);
      expect(FieldValidator.validate(field, 'not-a-number'),
          'Please enter a valid number');
    });

    test('validates email addresses', () {
      const field = FormFieldDefinition(
        id: 'f3',
        formId: 'form-1',
        key: 'email',
        label: 'Email',
        fieldType: FormFieldType.email,
      );

      expect(FieldValidator.validate(field, 'invalid-email'),
          'Please enter a valid email address');
      expect(FieldValidator.validate(field, 'user@example.com'), isNull);
    });

    test('validates custom regex patterns', () {
      const field = FormFieldDefinition(
        id: 'f4',
        formId: 'form-1',
        key: 'code',
        label: 'Product Code',
        fieldType: FormFieldType.text,
        validationRegex: r'^[A-Z]{3}-\d{4}$',
        customErrorMessage: 'Code must follow ABC-1234 pattern',
      );

      expect(FieldValidator.validate(field, 'abc-12'),
          'Code must follow ABC-1234 pattern');
      expect(FieldValidator.validate(field, 'ABC-9999'), isNull);
    });
  });
}
