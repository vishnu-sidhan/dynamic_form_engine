import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:dynamic_form_engine_example/presentation/views/home_catalog_screen.dart';
import 'package:dynamic_form_engine_example/presentation/views/template_submissions_screen.dart';
import 'package:dynamic_form_engine_example/services/persistent_storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory docDir;
  FakePathProviderPlatform(this.docDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => docDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PersistentStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('home_catalog_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);

    storage = PersistentStorageService();
    await storage.initialize();

    await storage.saveTemplate(
      const FormTemplate(
        id: 'test_safety_inspection',
        title: 'Safety Inspection',
        description: 'Routine site validation checks',
        version: 1,
        fields: [
          FormFieldDefinition(
            id: 'inspector_name',
            label: 'Inspector Name',
            type: FormFieldType.text,
            isRequired: true,
          ),
        ],
      ),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('HomeCatalogScreen renders templates, badges and navigates to submissions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeCatalogScreen(storageAdapter: storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dynamic Form Engine'), findsOneWidget);
    expect(find.text('Safety Inspection'), findsOneWidget);
    expect(find.text('0 submissions'), findsOneWidget);
    expect(find.text('1 Fields • v1'), findsOneWidget);
    expect(find.text('Create Form'), findsOneWidget);

    // Tap on card to navigate to TemplateSubmissionsScreen
    await tester.tap(find.text('Safety Inspection'));
    await tester.pumpAndSettle();

    expect(find.byType(TemplateSubmissionsScreen), findsOneWidget);
    expect(find.text('No submissions recorded yet'), findsOneWidget);
    expect(find.text('Fill Form'), findsOneWidget);
  });

  testWidgets('HomeCatalogScreen opens BackupExportSheet on import_export tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeCatalogScreen(storageAdapter: storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.import_export_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.import_export_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Export Backup (Save to Drive / Files)'), findsOneWidget);
    expect(find.text('Restore from Backup ZIP'), findsOneWidget);
  });

  testWidgets('HomeCatalogScreen card popup menu shows export and fill options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeCatalogScreen(storageAdapter: storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Fill Form'), findsOneWidget);
    expect(find.text('Submissions'), findsWidgets);
    expect(find.text('Export JSON'), findsOneWidget);

    // Dismiss menu
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('TemplateSubmissionsScreen renders Export Submissions and Backup & Restore actions', (tester) async {
    final template = (await storage.getTemplates()).first;

    await tester.pumpWidget(
      MaterialApp(
        home: TemplateSubmissionsScreen(
          template: template,
          storageAdapter: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
  });
}
