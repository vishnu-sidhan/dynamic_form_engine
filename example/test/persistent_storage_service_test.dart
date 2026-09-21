import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
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
    tempDir = await Directory.systemTemp.createTemp('sembast_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);

    storage = PersistentStorageService();
    await storage.initialize();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('PersistentStorageService saves and retrieves templates and submissions', () async {
    const template = FormTemplate(
      id: 'test_tmpl_1',
      title: 'Test Template',
      description: 'A test form template',
      version: 1,
      fields: [
        FormFieldDefinition(
          id: 'field_1',
          label: 'Name',
          type: FormFieldType.text,
          isRequired: true,
        ),
      ],
    );

    await storage.saveTemplate(template);
    final fetchedTemplates = await storage.getTemplates();
    expect(fetchedTemplates.length, 1);
    expect(fetchedTemplates.first.id, 'test_tmpl_1');
    expect(fetchedTemplates.first.title, 'Test Template');

    final fetchedOne = await storage.getTemplate('test_tmpl_1');
    expect(fetchedOne, isNotNull);
    expect(fetchedOne!.title, 'Test Template');

    final submission = FormSubmission(
      id: 'sub_1',
      templateId: 'test_tmpl_1',
      data: {'field_1': 'Antigravity User'},
      submittedAt: DateTime.now().toUtc(),
    );

    await storage.saveSubmission(submission);
    final fetchedSubmissions = await storage.getSubmissions();
    expect(fetchedSubmissions.length, 1);
    expect(fetchedSubmissions.first.templateId, 'test_tmpl_1');
    expect(fetchedSubmissions.first.data['field_1'], 'Antigravity User');

    // Delete submission & template
    await storage.deleteSubmission('sub_1', softDelete: false);
    expect((await storage.getSubmissions()).isEmpty, isTrue);

    await storage.deleteTemplate('test_tmpl_1', softDelete: false);
    expect((await storage.getTemplates()).isEmpty, isTrue);
  });
}
