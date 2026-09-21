// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/backup_export_sheet.dart';
import '../../services/backup/form_backup_manager.dart';
import '../../services/example_platform_handlers.dart';

class TemplateSubmissionsScreen extends StatefulWidget {
  final FormTemplate template;
  final FormStorageAdapter storageAdapter;
  final FormBackupManager? backupManager;

  const TemplateSubmissionsScreen({
    super.key,
    required this.template,
    required this.storageAdapter,
    this.backupManager,
  });

  @override
  State<TemplateSubmissionsScreen> createState() => _TemplateSubmissionsScreenState();
}

class _TemplateSubmissionsScreenState extends State<TemplateSubmissionsScreen> {
  late FormTemplate _currentTemplate;
  late Future<List<FormSubmission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _currentTemplate = widget.template;
    _loadSubmissions();
  }

  void _loadSubmissions() {
    setState(() {
      _submissionsFuture = widget.storageAdapter.getSubmissions().then(
            (list) => list
                .where((s) => s.templateId == _currentTemplate.id)
                .toList(),
          );
    });
  }

  Future<void> _navigateToEditForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: Text('Edit: ${_currentTemplate.title}')),
          body: DynamicFormCreatorView(
            initialTemplate: _currentTemplate,
            storageAdapter: widget.storageAdapter,
            onSaved: (updatedTemplate) {
              if (routeContext.mounted) {
                Navigator.pop(routeContext, updatedTemplate);
              }
            },
          ),
        ),
      ),
    );

    final refreshed =
        await widget.storageAdapter.getTemplate(_currentTemplate.id);
    if (refreshed != null && mounted) {
      setState(() {
        _currentTemplate = refreshed;
      });
      _loadSubmissions();
    }
  }

  Future<void> _confirmAndDeleteTemplate() async {
    final subs = await _submissionsFuture;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Form Template?'),
        content: Text(
          subs.isNotEmpty
              ? 'Are you sure you want to delete "${_currentTemplate.title}"?\n\nThis will also delete ${subs.length} associated submission${subs.length == 1 ? '' : 's'}. This action cannot be undone.'
              : 'Are you sure you want to delete "${_currentTemplate.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final s in subs) {
        await widget.storageAdapter.deleteSubmission(s.id, softDelete: false);
      }
      await widget.storageAdapter
          .deleteTemplate(_currentTemplate.id, softDelete: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form "${_currentTemplate.title}" deleted')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _exportSubmissionsJson(List<FormSubmission> subs) async {
    try {
      final list = subs.map((s) => s.toMap()).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(list);
      final filename = '${_currentTemplate.id}_submissions.json';
      final xFile = XFile.fromData(
        utf8.encode(jsonStr),
        mimeType: 'application/json',
        name: filename,
      );

      if (kIsWeb) {
        await xFile.saveTo(filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported submissions to $filename')),
          );
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Submissions for ${_currentTemplate.title}',
          subject: 'Form Submissions Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTemplate.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Submissions',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Submissions (JSON)',
            onPressed: () async {
              final subs = await _submissionsFuture;
              if (subs.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No submissions to export.')),
                  );
                }
                return;
              }
              await _exportSubmissionsJson(subs);
            },
          ),
          if (widget.backupManager != null)
            IconButton(
              icon: const Icon(Icons.import_export_rounded),
              tooltip: 'Backup & Restore (Export / Import)',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BackupExportSheet(
                    backupManager: widget.backupManager!,
                    onRestored: _loadSubmissions,
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadSubmissions,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Form Options',
            onSelected: (val) async {
              if (val == 'edit') {
                await _navigateToEditForm();
              } else if (val == 'delete') {
                await _confirmAndDeleteTemplate();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Form'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Form',
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<FormSubmission>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final submissions = snapshot.data ?? [];

          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No submissions recorded yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Tap "Fill Form" below to submit an entry.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: submissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = submissions[index];
              final dateStr = item.submittedAt.toLocal().toString().split('.')[0];

              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    'Submission #${item.id.substring(0, item.id.length > 8 ? 8 : item.id.length)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Submitted: $dateStr\nFields filled: ${item.data.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Submission Details')),
                          body: DynamicSubmissionDetailView(
                            submission: item,
                            template: _currentTemplate,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit_document),
        label: const Text('Fill Form'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (routeContext) => Scaffold(
                appBar: AppBar(title: Text('Fill: ${_currentTemplate.title}')),
                body: DynamicFormFillView(
                  template: _currentTemplate,
                  registry: createFunctionalExampleRegistry(),
                  onSubmit: (submissionData) async {
                    final submission = FormSubmission(
                      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                      templateId: _currentTemplate.id,
                      data: submissionData,
                      submittedAt: DateTime.now().toUtc(),
                    );
                    await widget.storageAdapter.saveSubmission(submission);
                    if (routeContext.mounted) Navigator.pop(routeContext);
                  },
                ),
              ),
            ),
          );
          _loadSubmissions();
        },
      ),
    );
  }
}
