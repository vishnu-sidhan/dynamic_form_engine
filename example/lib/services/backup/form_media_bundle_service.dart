import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:io';
import 'package:archive/archive.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FormMediaBundleService {
  final FormStorageAdapter storageAdapter;

  FormMediaBundleService({required this.storageAdapter});

  bool _isLocalFilePath(dynamic value) {
    if (kIsWeb) return false;
    if (value is! String) return false;
    try {
      return (value.startsWith('/') ||
              value.startsWith(RegExp(r'^[a-zA-Z]:\\'))) &&
          File(value).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<Directory> _getSafeTemporaryDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Temporary directories are not available on Web.');
    }
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<Directory> _getSafeDocumentsDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Documents directories are not available on Web.');
    }
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          Directory.systemTemp.path;
      final dir = Directory(p.join(home, 'Documents', 'DynamicFormEngine'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }
  }

  /// Exports local database and any media into pure in-memory ZIP bytes.
  /// Works across Web, macOS, iOS, Android, Linux, and Windows.
  Future<Uint8List> createZipBackupBytes() async {
    final templates = await storageAdapter.getTemplates();
    final rawSubmissions = await storageAdapter.getSubmissions();
    final portableSubmissions = <Map<String, dynamic>>[];

    final archive = Archive();

    for (final submission in rawSubmissions) {
      final submissionMap = submission.toJson();
      final Map<String, dynamic> dataMap =
          Map<String, dynamic>.from(submission.data);

      for (final entry in submission.data.entries) {
        final val = entry.value;

        if (!kIsWeb && _isLocalFilePath(val)) {
          try {
            final sourceFile = File(val as String);
            if (sourceFile.existsSync()) {
              final bytes = await sourceFile.readAsBytes();
              final extension = p.extension(sourceFile.path);
              final relativeName = 'media/${submission.id}_${entry.key}$extension';
              archive.addFile(ArchiveFile(relativeName, bytes.length, bytes));
              dataMap[entry.key] = relativeName;
            }
          } catch (_) {}
        } else if (!kIsWeb && val is List) {
          final updatedList = [];
          for (int i = 0; i < val.length; i++) {
            final item = val[i];
            if (_isLocalFilePath(item)) {
              try {
                final sourceFile = File(item as String);
                if (sourceFile.existsSync()) {
                  final bytes = await sourceFile.readAsBytes();
                  final extension = p.extension(sourceFile.path);
                  final relativeName =
                      'media/${submission.id}_${entry.key}_$i$extension';
                  archive.addFile(ArchiveFile(relativeName, bytes.length, bytes));
                  updatedList.add(relativeName);
                  continue;
                }
              } catch (_) {}
            }
            updatedList.add(item);
          }
          dataMap[entry.key] = updatedList;
        }
      }

      submissionMap['data'] = dataMap;
      submissionMap['answers'] = dataMap;
      portableSubmissions.add(submissionMap);
    }

    final manifest = {
      'schemaVersion': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'templates': templates.map((t) => t.toJson()).toList(),
      'submissions': portableSubmissions,
    };

    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData ?? []);
  }

  /// Exports local database and copies all linked media to a disk-safe ZIP archive.
  Future<File> createZipBackup() async {
    final bytes = await createZipBackupBytes();
    final tempDir = await _getSafeTemporaryDirectory();
    final zipPath = p.join(
      tempDir.path,
      'form_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(bytes);
    return zipFile;
  }

  /// Restores templates and submissions from raw ZIP archive bytes.
  /// Works across Web, desktop, and mobile.
  Future<void> restoreFromZipBytes(List<int> zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    Map<String, dynamic>? manifestData;
    final mediaFiles = <String, List<int>>{};

    for (final file in archive) {
      if (file.isFile) {
        if (file.name == 'manifest.json') {
          final content = utf8.decode(file.content as List<int>);
          manifestData = jsonDecode(content) as Map<String, dynamic>;
        } else if (file.name.startsWith('media/')) {
          mediaFiles[file.name] = file.content as List<int>;
        }
      }
    }

    if (manifestData == null) {
      throw const FormatException(
          'Invalid backup archive: missing manifest.json');
    }

    String? mediaStoragePath;
    if (!kIsWeb) {
      try {
        final appDocDir = await _getSafeDocumentsDirectory();
        final mediaDir = Directory(p.join(appDocDir.path, 'restored_media'));
        await mediaDir.create(recursive: true);
        mediaStoragePath = mediaDir.path;

        for (final entry in mediaFiles.entries) {
          final fileName = p.basename(entry.key);
          final outFile = File(p.join(mediaDir.path, fileName));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(entry.value);
        }
      } catch (_) {}
    }

    if (manifestData['templates'] is List) {
      for (final t in manifestData['templates']) {
        await storageAdapter.saveTemplate(
          FormTemplate.fromJson(t as Map<String, dynamic>),
        );
      }
    }

    if (manifestData['submissions'] is List) {
      for (final rawSub in manifestData['submissions']) {
        final subMap = Map<String, dynamic>.from(rawSub as Map);
        final dataMap = Map<String, dynamic>.from(subMap['data'] as Map);

        if (mediaStoragePath != null) {
          for (final entry in dataMap.entries) {
            final val = entry.value;
            if (val is String && val.startsWith('media/')) {
              dataMap[entry.key] = p.join(mediaStoragePath, p.basename(val));
            } else if (val is List) {
              dataMap[entry.key] = val.map((item) {
                if (item is String && item.startsWith('media/')) {
                  return p.join(mediaStoragePath!, p.basename(item));
                }
                return item;
              }).toList();
            }
          }
        }

        subMap['data'] = dataMap;
        subMap['answers'] = dataMap;
        await storageAdapter.saveSubmission(FormSubmission.fromJson(subMap));
      }
    }
  }

  /// Unpacks ZIP file, restores media files to application documents, and persists records.
  Future<void> restoreFromZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    await restoreFromZipBytes(bytes);
  }
}
