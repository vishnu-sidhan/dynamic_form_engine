import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

void main() {
  group('DynamicFormCreatorView', () {
    testWidgets('auto-generates field key and locks it from user editing', (tester) async {
      FormTemplate? savedTemplate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicFormCreatorView(
              onSaved: (template) {
                savedTemplate = template;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter form title
      final titleFinder = find.widgetWithText(TextFormField, 'Form Title *');
      await tester.enterText(titleFinder, 'Customer Feedback');
      await tester.pumpAndSettle();

      // Tap Add Field button
      await tester.tap(find.text('Add Field'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Add Form Field'), findsOneWidget);

      // Verify Field Key text field is readOnly and disabled
      final keyFinder = find.widgetWithText(TextField, 'Field Key (Auto-generated)');
      expect(keyFinder, findsOneWidget);
      final keyTextField = tester.widget<TextField>(keyFinder);
      expect(keyTextField.readOnly, isTrue);
      expect(keyTextField.enabled, isFalse);

      // Enter label
      final labelFinder = find.widgetWithText(TextField, 'Field Label *');
      await tester.enterText(labelFinder, 'Customer Phone Number');
      await tester.pumpAndSettle();

      // Verify the key field automatically reflected the slug
      final updatedKeyTextField = tester.widget<TextField>(keyFinder);
      expect(updatedKeyTextField.controller?.text, 'customer_phone_number');

      // Tap Save Field
      await tester.tap(find.text('Save Field'));
      await tester.pumpAndSettle();

      // Field appears in creator list
      expect(find.text('Customer Phone Number'), findsOneWidget);
      expect(find.text('Type: text'), findsOneWidget);

      // Save Template
      await tester.ensureVisible(find.text('Save Template'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(savedTemplate, isNotNull);
      expect(savedTemplate!.title, 'Customer Feedback');
      expect(savedTemplate!.fields.length, 1);
      expect(savedTemplate!.fields.first.key, 'customer_phone_number');
      expect(savedTemplate!.fields.first.label, 'Customer Phone Number');
    });

    testWidgets('shows min and max inputs for number, decimal, and currency fields', (tester) async {
      FormTemplate? savedTemplate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicFormCreatorView(
              onSaved: (template) {
                savedTemplate = template;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter form title
      await tester.enterText(find.widgetWithText(TextFormField, 'Form Title *'), 'Financials');
      await tester.pumpAndSettle();

      // Open Add Field dialog
      await tester.tap(find.text('Add Field'));
      await tester.pumpAndSettle();

      // Open Field Type dropdown and select 'currency'
      await tester.tap(find.text('text'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('currency').last);
      await tester.pumpAndSettle();

      // Min and Max inputs should now be visible
      expect(find.widgetWithText(TextField, 'Min Value (Optional)'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Max Value (Optional)'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Field Label *'), 'Annual Revenue');
      await tester.enterText(find.widgetWithText(TextField, 'Min Value (Optional)'), '1000');
      await tester.enterText(find.widgetWithText(TextField, 'Max Value (Optional)'), '500000');
      await tester.pumpAndSettle();

      // Save Field
      await tester.tap(find.text('Save Field'));
      await tester.pumpAndSettle();

      // Save Template
      await tester.ensureVisible(find.text('Save Template'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(savedTemplate, isNotNull);
      expect(savedTemplate!.fields.first.key, 'annual_revenue');
      expect(savedTemplate!.fields.first.fieldType, FormFieldType.currency);
      expect(savedTemplate!.fields.first.min, 1000);
      expect(savedTemplate!.fields.first.max, 500000);
    });
  });
}
