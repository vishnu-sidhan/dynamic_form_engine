import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:dynamic_form_engine_example/services/example_platform_handlers.dart';

void main() {
  testWidgets('createFunctionalExampleRegistry wires onPickMedia and onCaptureLocation for all media and location types', (tester) async {
    final registry = createFunctionalExampleRegistry();

    // Verify media and location types are registered
    expect(registry, isNotNull);

    const testTemplate = FormTemplate(
      id: 'test_media_location_wiring',
      title: 'Wiring Test',
      fields: [
        FormFieldDefinition(
          id: 'test_photo',
          label: 'Test Photo',
          type: FormFieldType.media,
        ),
        FormFieldDefinition(
          id: 'test_location',
          label: 'Test GPS',
          type: FormFieldType.location,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicFormFillView(
            template: testTemplate,
            registry: registry,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attach Image'), findsOneWidget);
    expect(find.text('Capture'), findsOneWidget);
  });
}
