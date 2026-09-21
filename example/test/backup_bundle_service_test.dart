import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:archive/archive_io.dart';
import 'package:dynamic_form_engine_example/services/backup/form_media_bundle_service.dart';
import 'package:dynamic_form_engine_example/services/backup/form_backup_manager.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory tempDir;
  final Directory docDir;

  FakePathProviderPlatform({required this.tempDir, required this.docDir});

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => docDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testTempDir;
  late Directory testDocDir;
  late DefaultSembastStorageAdapter storageAdapter;

  setUp(() async {
    testTempDir = await Directory.systemTemp.createTemp('backup_test_temp_');
    testDocDir = await Directory.systemTemp.createTemp('backup_test_doc_');

    PathProviderPlatform.instance = FakePathProviderPlatform(
      tempDir: testTempDir,
      docDir: testDocDir,
    );

    storageAdapter = DefaultSembastStorageAdapter(
      databasePath: 'test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await storageAdapter.initialize();
  });

  tearDown(() async {
    if (await testTempDir.exists()) {
      await testTempDir.delete(recursive: true);
    }
    if (await testDocDir.exists()) {
      await testDocDir.delete(recursive: true);
    }
  });

  group('FormMediaBundleService Tests', () {
    test('createZipBackup correctly packages templates, submissions, and media',
        () async {
      final template = FormTemplate(
        id: 'test_template_1',
        name: 'Test Template',
        createdAt: DateTime.now(),
        fields: const [
          FormFieldDefinition(
            id: 'photo',
            formId: 'test_template_1',
            key: 'photo',
            label: 'Photo',
            fieldType: FormFieldType.image,
          ),
        ],
      );
      await storageAdapter.saveTemplate(template);

      final sampleMediaFile = File(p.join(testTempDir.path, 'sample_photo.jpg'));
      await sampleMediaFile.writeAsString('fake image binary data');

      final submission = FormSubmission(
        id: 'submission_101',
        formId: 'test_template_1',
        submittedAt: DateTime.now(),
        answers: {'photo': sampleMediaFile.path},
      );
      await storageAdapter.saveSubmission(submission);

      final bundleService =
          FormMediaBundleService(storageAdapter: storageAdapter);
      final zipFile = await bundleService.createZipBackup();

      expect(await zipFile.exists(), isTrue);

      final inputStream = InputFileStream(zipFile.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      bool foundManifest = false;
      bool foundMedia = false;
      Map<String, dynamic>? manifestJson;

      for (final file in archive) {
        if (file.name == 'manifest.json') {
          foundManifest = true;
          manifestJson =
              jsonDecode(utf8.decode(file.content as List<int>))
                  as Map<String, dynamic>;
        } else if (file.name.startsWith('media/submission_101_photo')) {
          foundMedia = true;
          expect(utf8.decode(file.content as List<int>), 'fake image binary data');
        }
      }

      expect(foundManifest, isTrue);
      expect(foundMedia, isTrue);
      expect(manifestJson!['schemaVersion'], 1);
      final submissionsInManifest = manifestJson['submissions'] as List;
      expect(submissionsInManifest.length, 1);
      expect(
        submissionsInManifest.first['data']['photo'],
        'media/submission_101_photo.jpg',
      );
    });

    test('restoreFromZip restores media to app storage and database entries',
        () async {
      final template = FormTemplate(
        id: 'template_restore',
        name: 'Restore Form',
        createdAt: DateTime.now(),
      );
      await storageAdapter.saveTemplate(template);

      final mediaFile = File(p.join(testTempDir.path, 'document.pdf'));
      await mediaFile.writeAsString('test document contents');

      final submission = FormSubmission(
        id: 'sub_restore_1',
        formId: 'template_restore',
        submittedAt: DateTime.now(),
        answers: {'doc': mediaFile.path},
      );
      await storageAdapter.saveSubmission(submission);

      final bundleService =
          FormMediaBundleService(storageAdapter: storageAdapter);
      final zipFile = await bundleService.createZipBackup();

      final freshStorage = DefaultSembastStorageAdapter(
        databasePath: 'fresh_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      await freshStorage.initialize();

      expect(await freshStorage.getTemplates(), isEmpty);
      expect(await freshStorage.getSubmissions(), isEmpty);

      final restoreService =
          FormMediaBundleService(storageAdapter: freshStorage);
      await restoreService.restoreFromZip(zipFile);

      final restoredTemplates = await freshStorage.getTemplates();
      expect(restoredTemplates.length, 1);
      expect(restoredTemplates.first.id, 'template_restore');

      final restoredSubmissions = await freshStorage.getSubmissions();
      expect(restoredSubmissions.length, 1);
      final restoredSub = restoredSubmissions.first;
      expect(restoredSub.id, 'sub_restore_1');

      final restoredPath = restoredSub.data['doc'] as String;
      expect(
        p.canonicalize(restoredPath).startsWith(p.canonicalize(testDocDir.path)),
        isTrue,
      );
      final restoredFile = File(restoredPath);
      expect(await restoredFile.exists(), isTrue);
      expect(await restoredFile.readAsString(), 'test document contents');
    });
  });

  group('FormBackupManager Tests', () {
    test('bundleService integrated in FormBackupManager produces valid archive',
        () async {
      final bundleService =
          FormMediaBundleService(storageAdapter: storageAdapter);
      final manager = FormBackupManager(bundleService: bundleService);

      final template = FormTemplate(
        id: 'manager_template',
        name: 'Manager Test',
        createdAt: DateTime.now(),
      );
      await storageAdapter.saveTemplate(template);

      final zipFile = await manager.bundleService.createZipBackup();
      expect(await zipFile.exists(), isTrue);

      final cleanStorage = DefaultSembastStorageAdapter(
        databasePath: 'clean_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      await cleanStorage.initialize();
      await FormMediaBundleService(storageAdapter: cleanStorage)
          .restoreFromZip(zipFile);

      final restored = await cleanStorage.getTemplates();
      expect(restored.length, 1);
      expect(restored.first.id, 'manager_template');
    });
  });
}
