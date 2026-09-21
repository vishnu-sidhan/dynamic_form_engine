import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:dynamic_form_engine/src/presentation/renderers/location_field_renderer.dart';
import 'package:dynamic_form_engine/src/presentation/renderers/media_field_renderer.dart';

void main() {
  group('LocationFieldRenderer tests', () {
    late FormFlowController controller;

    setUp(() {
      final template = FormTemplate(
        id: 'test_tmpl',
        name: 'Test Template',
        createdAt: DateTime.now(),
        fields: const [
          FormFieldDefinition(
            id: 'gps_1',
            formId: 'test_tmpl',
            key: 'gps_1',
            label: 'Field GPS',
            fieldType: FormFieldType.gps,
          ),
        ],
      );
      controller = FormFlowController(template: template);
    });

    testWidgets('calls onCaptureLocation and updates value without opening manual dialog', (tester) async {
      bool onCaptureCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => LocationFieldRenderer(
                field: controller.fields.first,
                controller: controller,
                onCaptureLocation: (ctx, f) async {
                  onCaptureCalled = true;
                  return '12.9716, 77.5946';
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('No coordinates recorded'), findsOneWidget);
      await tester.tap(find.text('Capture'));
      await tester.pumpAndSettle();

      expect(onCaptureCalled, isTrue);
      expect(controller.getAnswer('gps_1'), '12.9716, 77.5946');
      expect(find.text('12.9716, 77.5946'), findsOneWidget);
      // Ensure manual dialog (Latitude, Longitude) did not appear
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('onCaptureLocation returning null does NOT open manual dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => LocationFieldRenderer(
                field: controller.fields.first,
                controller: controller,
                onCaptureLocation: (ctx, f) async => null,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Capture'));
      await tester.pumpAndSettle();

      expect(controller.getAnswer('gps_1'), isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('when onCaptureLocation is null, tapping Capture opens manual dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => LocationFieldRenderer(
                field: controller.fields.first,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Capture'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Latitude, Longitude'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '10.0, 20.0');
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(controller.getAnswer('gps_1'), '10.0, 20.0');
    });
  });

  group('MediaFieldRenderer tests', () {
    late FormFlowController controller;

    setUp(() {
      final template = FormTemplate(
        id: 'test_tmpl_media',
        name: 'Test Media Template',
        createdAt: DateTime.now(),
        fields: const [
          FormFieldDefinition(
            id: 'photo_1',
            formId: 'test_tmpl_media',
            key: 'photo_1',
            label: 'Photo Evidence',
            fieldType: FormFieldType.image,
          ),
        ],
      );
      controller = FormFlowController(template: template);
    });

    testWidgets('calls onPickMedia and updates value without opening manual dialog', (tester) async {
      bool onPickCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => MediaFieldRenderer(
                field: controller.fields.first,
                controller: controller,
                onPickMedia: (ctx, f) async {
                  onPickCalled = true;
                  return 'photo.jpg (120 KB)';
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach Image'));
      await tester.pumpAndSettle();

      expect(onPickCalled, isTrue);
      expect(controller.getAnswer('photo_1'), 'photo.jpg (120 KB)');
      expect(find.text('photo.jpg (120 KB)'), findsWidgets);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('onPickMedia returning null does NOT open manual dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => MediaFieldRenderer(
                field: controller.fields.first,
                controller: controller,
                onPickMedia: (ctx, f) async => null,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach Image'));
      await tester.pumpAndSettle();

      expect(controller.getAnswer('photo_1'), isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('when onPickMedia is null, tapping Attach Image opens manual dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => MediaFieldRenderer(
                field: controller.fields.first,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attach Image'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Media Path or URL'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'https://example.com/image.png');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(controller.getAnswer('photo_1'), 'https://example.com/image.png');
    });
  });
}
