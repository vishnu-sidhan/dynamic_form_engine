import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'form_media_bundle_service.dart';

class FormBackupManager {
  final FormMediaBundleService bundleService;

  FormBackupManager({required this.bundleService});

  /// Creates full backup ZIP and invokes web download or the OS share sheet
  Future<void> exportAndShareBackup() async {
    final zipBytes = await bundleService.createZipBackupBytes();
    final filename =
        'form_backup_${DateTime.now().millisecondsSinceEpoch}.zip';

    final xFile = XFile.fromData(
      zipBytes,
      mimeType: 'application/zip',
      name: filename,
    );

    if (kIsWeb) {
      // In web browser, saveTo directly triggers a browser file download to Downloads
      await xFile.saveTo(filename);
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Dynamic Form Engine Backup (Data & Media)',
          subject: 'Form Backup Archive',
          title: 'Form Backup Archive',
        ),
      );
    } catch (_) {
      // Fallback: save to disk via xFile
      await xFile.saveTo(filename);
    }
  }

  /// Opens native/web file picker to pick a .zip backup archive and restores it
  Future<bool> pickAndRestoreBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (files.isEmpty) {
      return false; // User cancelled
    }

    final picked = files.first;
    final bytes = await picked.xFile.readAsBytes();

    if (bytes.isEmpty) {
      return false;
    }

    await bundleService.restoreFromZipBytes(bytes);
    return true;
  }
}
