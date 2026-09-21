import 'package:flutter/material.dart';
import '../../services/backup/form_backup_manager.dart';

class BackupExportSheet extends StatefulWidget {
  final FormBackupManager backupManager;
  final VoidCallback? onRestored;

  const BackupExportSheet({
    super.key,
    required this.backupManager,
    this.onRestored,
  });

  @override
  State<BackupExportSheet> createState() => _BackupExportSheetState();
}

class _BackupExportSheetState extends State<BackupExportSheet> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _handleExport() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Bundling forms and media into ZIP...';
    });

    try {
      await widget.backupManager.exportAndShareBackup();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Export failed: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening file picker...';
    });

    try {
      final restored = await widget.backupManager.pickAndRestoreBackup();
      if (!mounted) return;

      if (restored) {
        widget.onRestored?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully!')),
        );
      } else {
        setState(() => _statusMessage = 'Restore cancelled.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Restore failed: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.archive_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup & Restore',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Offline-first full state archive',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Export your forms, responses, images, and attachments as a ZIP file, or restore from an existing backup archive.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Export Backup (Save to Drive / Files)'),
              onPressed: _isLoading ? null : _handleExport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.restore_page),
              label: const Text('Restore from Backup ZIP'),
              onPressed: _isLoading ? null : _handleRestore,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ] else if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
