import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'package:dynamic_form_engine_example/presentation/views/home_catalog_screen.dart';
import 'package:dynamic_form_engine_example/presentation/views/template_submissions_screen.dart';

class FakeFormStorageAdapter implements FormStorageAdapter {
  final Map<String, FormTemplate> templates = {};
  final Map<String, FormSubmission> submissions = {};
  final List<OutboxMutation> outbox = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveTemplate(FormTemplate template) async {
    templates[template.id] = template;
  }

  @override
  Future<FormTemplate?> getTemplateById(String id) async => templates[id];

  @override
  Future<FormTemplate?> getTemplate(String id) => getTemplateById(id);

  @override
  Future<List<FormTemplate>> getTemplates({
    String? contextScope,
    bool includeArchived = false,
  }) async {
    return templates.values.where((t) {
      if (!includeArchived && t.deletedAt != null) return false;
      if (contextScope != null && contextScope.isNotEmpty) {
        if (t.contextScope != null &&
            t.contextScope != contextScope &&
            t.contextScope != 'global') {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<void> deleteTemplate(String id, {bool softDelete = true}) async {
    if (softDelete) {
      final existing = templates[id];
      if (existing != null) {
        templates[id] = existing.copyWith(deletedAt: DateTime.now());
      }
    } else {
      templates.remove(id);
    }
  }

  @override
  Future<void> saveSubmission(FormSubmission submission) async {
    submissions[submission.id] = submission;
  }

  @override
  Future<FormSubmission?> getSubmissionById(String id) async => submissions[id];

  @override
  Future<FormSubmission?> getSubmission(String id) => getSubmissionById(id);

  @override
  Future<List<FormSubmission>> getSubmissions({bool includeArchived = false}) async {
    return submissions.values.where((s) {
      if (!includeArchived && s.deletedAt != null) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<FormSubmission>> querySubmissions({
    required String formId,
    String? contextId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return submissions.values.where((s) => s.templateId == formId).toList();
  }

  @override
  Future<void> deleteSubmission(String id, {bool softDelete = true}) async {
    if (softDelete) {
      final existing = submissions[id];
      if (existing != null) {
        submissions[id] = existing.copyWith(deletedAt: DateTime.now());
      }
    } else {
      submissions.remove(id);
    }
  }

  @override
  Future<void> queueOutboxMutation(OutboxMutation mutation) async => outbox.add(mutation);

  @override
  Future<List<OutboxMutation>> getPendingOutboxMutations() async =>
      List.unmodifiable(outbox);

  @override
  Future<void> markOutboxMutationsSynced(List<String> mutationIds) async {
    outbox.removeWhere((m) => mutationIds.contains(m.id));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFormStorageAdapter storage;

  setUp(() async {
    storage = FakeFormStorageAdapter();
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

  testWidgets('HomeCatalogScreen card popup menu shows fill, edit, submissions, export and delete options', (tester) async {
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
    expect(find.text('Edit Form'), findsOneWidget);
    expect(find.text('Submissions'), findsWidgets);
    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Delete Form'), findsOneWidget);

    // Dismiss menu
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('HomeCatalogScreen deletes template after user confirms dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeCatalogScreen(storageAdapter: storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Safety Inspection'), findsOneWidget);

    // Open options menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Delete Form
    await tester.tap(find.text('Delete Form'));
    await tester.pumpAndSettle();

    // Confirm dialog is shown
    expect(find.text('Delete Form Template?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Cancel first to verify it does not delete
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Safety Inspection'), findsOneWidget);

    // Open options menu again and confirm delete
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Form'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // Form should now be deleted and catalog shows empty state
    expect(find.byType(Card), findsNothing);
    expect(find.text('No templates found'), findsOneWidget);
    expect(find.text('Form "Safety Inspection" deleted'), findsOneWidget);
  });

  testWidgets('HomeCatalogScreen edits existing template and updates catalog', (tester) async {
    // Re-seed template in case previous test deleted it
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

    await tester.pumpWidget(
      MaterialApp(
        home: HomeCatalogScreen(storageAdapter: storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Safety Inspection'), findsOneWidget);

    // Open options menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Edit Form
    await tester.tap(find.text('Edit Form'));
    await tester.pumpAndSettle();

    // Verify creator view opened in edit mode
    expect(find.text('Edit: Safety Inspection'), findsOneWidget);
    expect(find.text('Inspector Name'), findsOneWidget);

    // Modify the title
    final titleFinder = find.widgetWithText(TextFormField, 'Safety Inspection');
    await tester.enterText(titleFinder, 'Updated Safety Inspection');
    await tester.pumpAndSettle();

    // Scroll to and tap Update Template
    await tester.ensureVisible(find.text('Update Template'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Template'));
    await tester.pumpAndSettle();

    // Should return to catalog with updated title
    expect(find.text('Updated Safety Inspection'), findsOneWidget);
    expect(find.text('1 Fields • v2'), findsOneWidget);
  });

  testWidgets('TemplateSubmissionsScreen renders actions and options menu', (tester) async {
    const template = FormTemplate(
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
    );
    await storage.saveTemplate(template);

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
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    // Open options menu in submissions screen
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit Form'), findsOneWidget);
    expect(find.text('Delete Form'), findsOneWidget);

    // Dismiss menu
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });
}
