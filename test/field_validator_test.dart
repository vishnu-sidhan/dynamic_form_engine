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

    test('validates number integer constraints, min and max bounds', () {
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
      expect(FieldValidator.validate(field, '25.5'),
          'Please enter a whole number without decimals');
    });

    test('validates decimal values with commas, periods, and bounds', () {
      const field = FormFieldDefinition(
        id: 'f_dec',
        formId: 'form-1',
        key: 'rating',
        label: 'Rating',
        fieldType: FormFieldType.decimal,
        min: 0.5,
        max: 5.0,
      );

      expect(FieldValidator.validate(field, '4.5'), isNull);
      expect(FieldValidator.validate(field, '4,5'), isNull);
      expect(FieldValidator.validate(field, '0.2'), 'Minimum value is 0.5');
      expect(FieldValidator.validate(field, '5.5'), 'Maximum value is 5.0');
      expect(FieldValidator.validate(field, 'invalid'), 'Please enter a valid number');
    });

    test('validates currency values with symbols, commas, and bounds', () {
      const field = FormFieldDefinition(
        id: 'f_curr',
        formId: 'form-1',
        key: 'salary',
        label: 'Salary',
        fieldType: FormFieldType.currency,
        min: 1000,
        max: 100000,
      );

      expect(FieldValidator.validate(field, r'$5,000.50'), isNull);
      expect(FieldValidator.validate(field, '€2,500'), isNull);
      expect(FieldValidator.validate(field, '£75,000'), isNull);
      expect(FieldValidator.validate(field, '₹50,000.00'), isNull);
      expect(FieldValidator.validate(field, r'$500'), 'Minimum value is 1000');
      expect(FieldValidator.validate(field, r'$150,000'), 'Maximum value is 100000');
      expect(FieldValidator.validate(field, r'$$$'), 'Please enter a valid number');
    });

    test('validates phone numbers with international formats, dots, and digit counts', () {
      const field = FormFieldDefinition(
        id: 'f_phone',
        formId: 'form-1',
        key: 'phone_number',
        label: 'Phone Number',
        fieldType: FormFieldType.phone,
      );

      // Valid phone numbers
      expect(FieldValidator.validate(field, '+1 202 555 0192'), isNull);
      expect(FieldValidator.validate(field, '(555) 019-2834'), isNull);
      expect(FieldValidator.validate(field, '555.019.2834'), isNull);
      expect(FieldValidator.validate(field, '+442079460958'), isNull);
      expect(FieldValidator.validate(field, '1234567'), isNull); // 7 digits (min allowed)
      expect(FieldValidator.validate(field, '+123456789012345'), isNull); // 15 digits (max allowed)

      // Invalid phone numbers
      expect(FieldValidator.validate(field, '12345'),
          'Please enter a valid phone number (7 to 15 digits)');
      expect(FieldValidator.validate(field, '12345678901234567'),
          'Please enter a valid phone number (7 to 15 digits)');
      expect(FieldValidator.validate(field, '+---()---()'),
          'Please enter a valid phone number (7 to 15 digits)');
      expect(FieldValidator.validate(field, '555-CALL-NOW'),
          'Please enter a valid phone number');
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
