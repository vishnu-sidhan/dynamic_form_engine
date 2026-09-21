// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_brand_logo.dart';
import '../widgets/backup_export_sheet.dart';
import '../../services/backup/form_backup_manager.dart';
import '../../services/backup/form_media_bundle_service.dart';
import '../../services/example_platform_handlers.dart';
import 'template_submissions_screen.dart';

class HomeCatalogScreen extends StatefulWidget {
  final FormStorageAdapter storageAdapter;
  final FormBackupManager? backupManager;

  const HomeCatalogScreen({
    super.key,
    required this.storageAdapter,
    this.backupManager,
  });

  @override
  State<HomeCatalogScreen> createState() => _HomeCatalogScreenState();
}

class _HomeCatalogScreenState extends State<HomeCatalogScreen> {
  late Future<List<FormTemplate>> _templatesFuture;
  late Future<List<FormSubmission>> _submissionsFuture;
  late final FormBackupManager _backupManager = widget.backupManager ??
      FormBackupManager(
        bundleService:
            FormMediaBundleService(storageAdapter: widget.storageAdapter),
      );

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _templatesFuture = widget.storageAdapter.getTemplates();
      _submissionsFuture = widget.storageAdapter.getSubmissions();
    });
  }

  Future<void> _exportTemplateJson(FormTemplate template) async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(template.toMap());
      final filename = '${template.id}_template.json';
      final xFile = XFile.fromData(
        utf8.encode(jsonStr),
        mimeType: 'application/json',
        name: filename,
      );

      if (kIsWeb) {
        await xFile.saveTo(filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported template to $filename')),
          );
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Form Template: ${template.title}',
          subject: 'Form Template Export',
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

  Future<void> _navigateToFillForm(FormTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: Text('Fill: ${template.title}')),
          body: DynamicFormFillView(
            template: template,
            registry: createFunctionalExampleRegistry(),
            onSubmit: (submissionData) async {
              final submission = FormSubmission(
                id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                templateId: template.id,
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
    _refreshData();
  }

  Future<void> _navigateToCreateForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: const Text('Create Form Template')),
          body: DynamicFormCreatorView(
            storageAdapter: widget.storageAdapter,
            onSaved: (newTemplate) {
              if (routeContext.mounted) Navigator.pop(routeContext);
            },
          ),
        ),
      ),
    );
    _refreshData();
  }

  Future<void> _navigateToEditForm(FormTemplate template) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: Text('Edit: ${template.title}')),
          body: DynamicFormCreatorView(
            initialTemplate: template,
            storageAdapter: widget.storageAdapter,
            onSaved: (updatedTemplate) {
              if (routeContext.mounted) Navigator.pop(routeContext);
            },
          ),
        ),
      ),
    );
    _refreshData();
  }

  Future<void> _confirmAndDeleteTemplate(
    FormTemplate template,
    int submissionCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Form Template?'),
        content: Text(
          submissionCount > 0
              ? 'Are you sure you want to delete "${template.title}"?\n\nThis will also delete $submissionCount associated submission${submissionCount == 1 ? '' : 's'}. This action cannot be undone.'
              : 'Are you sure you want to delete "${template.title}"? This action cannot be undone.',
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
      final allSubmissions = await widget.storageAdapter.getSubmissions();
      final related =
          allSubmissions.where((s) => s.templateId == template.id).toList();
      for (final s in related) {
        await widget.storageAdapter.deleteSubmission(s.id, softDelete: false);
      }
      await widget.storageAdapter
          .deleteTemplate(template.id, softDelete: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form "${template.title}" deleted')),
        );
      }
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 480
        ? 1
        : width < 840
            ? 2
            : width < 1200
                ? 3
                : 4;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            SizedBox(width: 16),
            AppBrandLogo(size: 32),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Dynamic Form Engine',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export_rounded),
            tooltip: 'Backup & Restore (Export / Import)',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => BackupExportSheet(
                  backupManager: _backupManager,
                  onRestored: _refreshData,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_templatesFuture, _submissionsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Failed to load forms: ${snapshot.error}'),
              ),
            );
          }

          final templates = snapshot.data![0] as List<FormTemplate>;
          final submissions = snapshot.data![1] as List<FormSubmission>;

          if (templates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppBrandLogo(size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'No templates found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new form template or restore from an existing backup archive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create Form'),
                          onPressed: _navigateToCreateForm,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.restore_page),
                          label: const Text('Restore Backup ZIP'),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => BackupExportSheet(
                                backupManager: _backupManager,
                                onRestored: _refreshData,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.25,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final count = submissions.where((s) => s.templateId == template.id).length;

                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TemplateSubmissionsScreen(
                            template: template,
                            storageAdapter: widget.storageAdapter,
                            backupManager: _backupManager,
                          ),
                        ),
                      );
                      _refreshData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const Spacer(),
                              Badge(
                                label: Text('$count submissions'),
                                backgroundColor: count > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                textColor: count > 0
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                tooltip: 'Options',
                                onSelected: (val) async {
                                  if (val == 'export_json') {
                                    await _exportTemplateJson(template);
                                  } else if (val == 'fill') {
                                    await _navigateToFillForm(template);
                                  } else if (val == 'edit') {
                                    await _navigateToEditForm(template);
                                  } else if (val == 'submissions') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TemplateSubmissionsScreen(
                                          template: template,
                                          storageAdapter: widget.storageAdapter,
                                          backupManager: _backupManager,
                                        ),
                                      ),
                                    );
                                    _refreshData();
                                  } else if (val == 'delete') {
                                    await _confirmAndDeleteTemplate(
                                        template, count);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'fill',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_note, size: 18),
                                        SizedBox(width: 8),
                                        Text('Fill Form'),
                                      ],
                                    ),
                                  ),
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
                                  const PopupMenuItem(
                                    value: 'submissions',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.history_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Submissions'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'export_json',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.code_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Export JSON'),
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
                                            color:
                                                Theme.of(ctx).colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            template.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            template.description.isNotEmpty
                                ? template.description
                                : 'No description provided.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${template.fields.length} Fields • v${template.version}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Form'),
        onPressed: _navigateToCreateForm,
      ),
    );
  }
}
