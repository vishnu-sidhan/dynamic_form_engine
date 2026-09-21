import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

void main() {
  testWidgets('Submitting invalid form shows errors on all field types including checkbox', (tester) async {
    final template = FormTemplate(
      id: 'test_form',
      name: 'Test Form',
      createdAt: DateTime.now(),
      fields: const [
        FormFieldDefinition(
          id: 'name',
          formId: 'test_form',
          key: 'name',
          label: 'Name',
          fieldType: FormFieldType.text,
          isRequired: true,
        ),
        FormFieldDefinition(
          id: 'dept',
          formId: 'test_form',
          key: 'dept',
          label: 'Department',
          fieldType: FormFieldType.dropdown,
          isRequired: true,
          options: [
            FormOption(label: 'Dept A', value: 'a'),
            FormOption(label: 'Dept B', value: 'b'),
          ],
        ),
        FormFieldDefinition(
          id: 'agree',
          formId: 'test_form',
          key: 'agree',
          label: 'Agree to terms',
          fieldType: FormFieldType.checkbox,
          isRequired: true,
        ),
        FormFieldDefinition(
          id: 'team_members',
          formId: 'test_form',
          key: 'team_members',
          label: 'Team Members',
          fieldType: FormFieldType.groupRepeater,
          isRequired: true,
        ),
      ],
    );

    String? errorMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicFormFillView(
            template: template,
            onError: (err) {
              errorMessage = err;
            },
          ),
        ),
      ),
    );

    expect(find.text('Please correct the following errors:'), findsNothing);

    await tester.tap(find.text('Submit Form'));
    await tester.pumpAndSettle();

    expect(errorMessage, 'Please correct the errors in the form.');

    // In-form validation banner should be displayed
    expect(find.text('Please correct the following errors:'), findsOneWidget);

    // Text field error
    expect(find.text('This field is required'), findsWidgets);

    // Checkbox error should be displayed
    expect(find.text('Agree to terms'), findsWidgets);

    // Group repeater error
    expect(find.text('Please add at least one entry'), findsWidgets);
  });

  test('FieldValidator enforces isRequired on checkbox', () {
    const field = FormFieldDefinition(
      id: 'agree',
      formId: 'f1',
      key: 'agree',
      label: 'Agree to terms',
      fieldType: FormFieldType.checkbox,
      isRequired: true,
    );

    expect(FieldValidator.validate(field, null), 'This field is required');
    expect(FieldValidator.validate(field, ''), 'This field is required');
    expect(FieldValidator.validate(field, 'false'), 'This field is required');
    expect(FieldValidator.validate(field, false), 'This field is required');
    expect(FieldValidator.validate(field, 'true'), isNull);
    expect(FieldValidator.validate(field, true), isNull);
  });

  test('FieldValidator enforces isRequired on groupRepeater', () {
    const field = FormFieldDefinition(
      id: 'repeater',
      formId: 'f1',
      key: 'repeater',
      label: 'Items',
      fieldType: FormFieldType.groupRepeater,
      isRequired: true,
    );

    expect(FieldValidator.validate(field, null), 'Please add at least one entry');
    expect(FieldValidator.validate(field, ''), 'Please add at least one entry');
    expect(FieldValidator.validate(field, '[]'), 'Please add at least one entry');
    expect(FieldValidator.validate(field, []), 'Please add at least one entry');
    expect(FieldValidator.validate(field, '[{"name":"Alice"}]'), isNull);
  });
}
