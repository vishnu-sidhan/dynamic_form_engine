import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'services/example_platform_handlers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageAdapter = DefaultSembastStorageAdapter();
  await storageAdapter.initialize();

  // 1. Master Template demonstrating ALL 20+ FormFieldTypes
  final allTypesTemplate = FormTemplate(
    id: 'master_field_showcase',
    name: '1. All Field Types Master Showcase',
    description:
        'Comprehensive showcase demonstrating every supported field type: inputs, selectors, date-time, media, signatures, GPS, math formulas, and nested group repeaters.',
    createdAt: DateTime.now(),
    fields: const [
      FormFieldDefinition(
        id: 'full_name',
        formId: 'master_field_showcase',
        key: 'full_name',
        label: 'Full Name',
        hint: 'Enter your full name',
        fieldType: FormFieldType.text,
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'contact_email',
        formId: 'master_field_showcase',
        key: 'contact_email',
        label: 'Email Address',
        hint: 'e.g. alex@example.com',
        fieldType: FormFieldType.email,
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'contact_phone',
        formId: 'master_field_showcase',
        key: 'contact_phone',
        label: 'Phone Number',
        hint: '+1 (555) 019-2834',
        fieldType: FormFieldType.phone,
      ),
      FormFieldDefinition(
        id: 'quantity_units',
        formId: 'master_field_showcase',
        key: 'quantity_units',
        label: 'Quantity Units',
        hint: 'Number of units',
        fieldType: FormFieldType.number,
        isRequired: true,
        min: 1,
      ),
      FormFieldDefinition(
        id: 'unit_rate',
        formId: 'master_field_showcase',
        key: 'unit_rate',
        label: 'Unit Rate (\$)',
        hint: 'Price per unit in USD',
        fieldType: FormFieldType.decimal,
        isRequired: true,
        min: 0.5,
      ),
      FormFieldDefinition(
        id: 'allocated_budget',
        formId: 'master_field_showcase',
        key: 'allocated_budget',
        label: 'Allocated Budget (\$)',
        hint: 'Approved project budget cap',
        fieldType: FormFieldType.currency,
      ),
      FormFieldDefinition(
        id: 'computed_subtotal',
        formId: 'master_field_showcase',
        key: 'computed_subtotal',
        label: 'Calculated Subtotal (\$)',
        hint: 'Dynamic math formula: [quantity_units] * [unit_rate]',
        fieldType: FormFieldType.calculated,
        calculationFormula: '[quantity_units] * [unit_rate]',
      ),
      FormFieldDefinition(
        id: 'department',
        formId: 'master_field_showcase',
        key: 'department',
        label: 'Assigned Department',
        hint: 'Select the responsible department',
        fieldType: FormFieldType.dropdown,
        isRequired: true,
        options: [
          FormOption(label: 'Engineering & Technology', value: 'engineering'),
          FormOption(label: 'Product & Design', value: 'product'),
          FormOption(label: 'Sales & Customer Success', value: 'sales'),
          FormOption(label: 'Operations & HR', value: 'operations'),
        ],
      ),
      FormFieldDefinition(
        id: 'priority_tier',
        formId: 'master_field_showcase',
        key: 'priority_tier',
        label: 'Priority Level',
        fieldType: FormFieldType.radio,
        options: [
          FormOption(label: 'Low (P3)', value: 'low'),
          FormOption(label: 'Standard (P2)', value: 'standard'),
          FormOption(label: 'High (P1)', value: 'high'),
          FormOption(label: 'Critical Urgent (P0)', value: 'critical'),
        ],
      ),
      FormFieldDefinition(
        id: 'subscribed_modules',
        formId: 'master_field_showcase',
        key: 'subscribed_modules',
        label: 'Select Enabled Modules',
        fieldType: FormFieldType.multiSelect,
        options: [
          FormOption(label: 'Identity & Access Management', value: 'iam'),
          FormOption(label: 'Real-time Telemetry', value: 'telemetry'),
          FormOption(label: 'Automated CI/CD Workflows', value: 'cicd'),
          FormOption(label: 'Compliance & Audit Loggers', value: 'audit'),
        ],
      ),
      FormFieldDefinition(
        id: 'enable_notifications',
        formId: 'master_field_showcase',
        key: 'enable_notifications',
        label: 'Enable Automated Alerts & Notifications',
        fieldType: FormFieldType.toggle,
      ),
      FormFieldDefinition(
        id: 'terms_accepted',
        formId: 'master_field_showcase',
        key: 'terms_accepted',
        label: 'I accept the Enterprise Service Terms and Data Privacy Policy',
        fieldType: FormFieldType.checkbox,
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'target_delivery_date',
        formId: 'master_field_showcase',
        key: 'target_delivery_date',
        label: 'Target Delivery Date',
        fieldType: FormFieldType.date,
      ),
      FormFieldDefinition(
        id: 'sync_time',
        formId: 'master_field_showcase',
        key: 'sync_time',
        label: 'Daily Standup Time',
        fieldType: FormFieldType.time,
      ),
      FormFieldDefinition(
        id: 'release_window',
        formId: 'master_field_showcase',
        key: 'release_window',
        label: 'Release Window Timestamp',
        fieldType: FormFieldType.dateTime,
      ),
      FormFieldDefinition(
        id: 'sprint_range',
        formId: 'master_field_showcase',
        key: 'sprint_range',
        label: 'Sprint Period (Start – End)',
        fieldType: FormFieldType.dateRange,
      ),
      FormFieldDefinition(
        id: 'project_narrative',
        formId: 'master_field_showcase',
        key: 'project_narrative',
        label: 'Detailed Project Summary & Scope',
        hint: 'Outline requirements, acceptance criteria, and notes',
        fieldType: FormFieldType.textarea,
      ),
      FormFieldDefinition(
        id: 'site_geotag',
        formId: 'master_field_showcase',
        key: 'site_geotag',
        label: 'Deployment Facility GPS Location',
        hint: 'Capture physical coordinates',
        fieldType: FormFieldType.gpsLocation,
      ),
      FormFieldDefinition(
        id: 'profile_image',
        formId: 'master_field_showcase',
        key: 'profile_image',
        label: 'Profile / Cover Photo',
        fieldType: FormFieldType.image,
      ),
      FormFieldDefinition(
        id: 'demo_video',
        formId: 'master_field_showcase',
        key: 'demo_video',
        label: 'Product Demo Screen Recording',
        fieldType: FormFieldType.video,
      ),
      FormFieldDefinition(
        id: 'spec_document',
        formId: 'master_field_showcase',
        key: 'spec_document',
        label: 'Technical Specification PDF',
        fieldType: FormFieldType.document,
      ),
      FormFieldDefinition(
        id: 'signoff_signature',
        formId: 'master_field_showcase',
        key: 'signoff_signature',
        label: 'Authorized Sign-Off Signature',
        hint: 'Sign directly on the canvas pad',
        fieldType: FormFieldType.signature,
      ),
      FormFieldDefinition(
        id: 'line_item_repeater',
        formId: 'master_field_showcase',
        key: 'line_item_repeater',
        label: 'Custom Deliverable Line Items',
        hint: 'Add repeating sub-items (Item, Units, Amount)',
        fieldType: FormFieldType.groupRepeater,
      ),
    ],
  );

  // 2. Work Order & Service Inspection Form (with conditional logic & formulas)
  final workOrderTemplate = FormTemplate(
    id: 'work_order_inspection',
    name: '2. Work Order & Service Inspection',
    description:
        'Enterprise maintenance and service work order with real-time fee calculation, conditional escalation triggers, GPS tagging, and signature.',
    createdAt: DateTime.now(),
    fields: const [
      FormFieldDefinition(
        id: 'client_company',
        formId: 'work_order_inspection',
        key: 'client_company',
        label: 'Client / Organization Name',
        hint: 'e.g. Acme Corp Industries',
        fieldType: FormFieldType.text,
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'service_tier',
        formId: 'work_order_inspection',
        key: 'service_tier',
        label: 'Service Agreement Tier',
        hint: 'Select the active SLA contract',
        fieldType: FormFieldType.dropdown,
        isRequired: true,
        options: [
          FormOption(label: 'Standard Business SLA', value: 'standard'),
          FormOption(label: 'Priority 24/7 Support', value: 'priority'),
          FormOption(label: 'Mission-Critical Dedicated', value: 'mission_critical'),
        ],
      ),
      FormFieldDefinition(
        id: 'service_hours',
        formId: 'work_order_inspection',
        key: 'service_hours',
        label: 'Billable Labor Hours',
        hint: 'Enter total technician hours',
        fieldType: FormFieldType.number,
        isRequired: true,
        min: 1,
      ),
      FormFieldDefinition(
        id: 'hourly_rate',
        formId: 'work_order_inspection',
        key: 'hourly_rate',
        label: 'Agreed Hourly Rate (\$)',
        hint: 'Contract billing rate',
        fieldType: FormFieldType.decimal,
        isRequired: true,
        min: 10.0,
      ),
      FormFieldDefinition(
        id: 'total_service_fee',
        formId: 'work_order_inspection',
        key: 'total_service_fee',
        label: 'Estimated Total Service Fee (\$)',
        hint: 'Dynamically calculated: [service_hours] * [hourly_rate]',
        fieldType: FormFieldType.calculated,
        calculationFormula: '[service_hours] * [hourly_rate]',
      ),
      FormFieldDefinition(
        id: 'requires_escalation',
        formId: 'work_order_inspection',
        key: 'requires_escalation',
        label: 'Flag Incident for Urgent Escalation?',
        fieldType: FormFieldType.checkbox,
      ),
      FormFieldDefinition(
        id: 'escalation_notes',
        formId: 'work_order_inspection',
        key: 'escalation_notes',
        label: 'Escalation Details & Root Cause Analysis',
        hint: 'Detail the failure mode, immediate risks, and mitigation steps',
        fieldType: FormFieldType.textarea,
        dependsOnFieldKey: 'requires_escalation',
        showIfValue: 'true',
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'facility_gps',
        formId: 'work_order_inspection',
        key: 'facility_gps',
        label: 'Client Facility GPS Location',
        hint: 'Geo-coordinate verification',
        fieldType: FormFieldType.gpsLocation,
      ),
      FormFieldDefinition(
        id: 'inspector_signoff',
        formId: 'work_order_inspection',
        key: 'inspector_signoff',
        label: 'Lead Inspector Verification Signature',
        hint: 'Draw signature to confirm service completion',
        fieldType: FormFieldType.signature,
      ),
    ],
  );

  // 3. Customer Satisfaction & Feedback Survey Form
  final feedbackSurveyTemplate = FormTemplate(
    id: 'customer_feedback_survey',
    name: '3. Customer Experience & Feedback Survey',
    description:
        'Product feedback and customer satisfaction survey demonstrating ratings, multiple-choice preferences, and toggles.',
    createdAt: DateTime.now(),
    fields: const [
      FormFieldDefinition(
        id: 'respondent_name',
        formId: 'customer_feedback_survey',
        key: 'respondent_name',
        label: 'Respondent Full Name',
        fieldType: FormFieldType.text,
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'overall_satisfaction',
        formId: 'customer_feedback_survey',
        key: 'overall_satisfaction',
        label: 'Overall Platform Experience',
        fieldType: FormFieldType.radio,
        isRequired: true,
        options: [
          FormOption(label: 'Outstanding (5/5)', value: 'outstanding'),
          FormOption(label: 'Satisfied (4/5)', value: 'satisfied'),
          FormOption(label: 'Neutral (3/5)', value: 'neutral'),
          FormOption(label: 'Needs Improvement (1-2/5)', value: 'needs_improvement'),
        ],
      ),
      FormFieldDefinition(
        id: 'favorite_capabilities',
        formId: 'customer_feedback_survey',
        key: 'favorite_capabilities',
        label: 'Key Features Most Valued',
        fieldType: FormFieldType.multiSelect,
        options: [
          FormOption(label: 'Pluggable Storage Adapters', value: 'storage'),
          FormOption(label: 'Real-time Formula Engine', value: 'formulas'),
          FormOption(label: 'Dynamic Field Visibility', value: 'visibility'),
          FormOption(label: 'Custom Slot Builders & Theming', value: 'ui_theming'),
        ],
      ),
      FormFieldDefinition(
        id: 'would_recommend',
        formId: 'customer_feedback_survey',
        key: 'would_recommend',
        label: 'Would you recommend this engine to other teams?',
        fieldType: FormFieldType.toggle,
      ),
      FormFieldDefinition(
        id: 'survey_comments',
        formId: 'customer_feedback_survey',
        key: 'survey_comments',
        label: 'What could we improve?',
        hint: 'Share any feature requests or feedback',
        fieldType: FormFieldType.textarea,
      ),
      FormFieldDefinition(
        id: 'completion_date',
        formId: 'customer_feedback_survey',
        key: 'completion_date',
        label: 'Date of Submission',
        fieldType: FormFieldType.date,
      ),
    ],
  );

  await storageAdapter.saveTemplate(allTypesTemplate);
  await storageAdapter.saveTemplate(workOrderTemplate);
  await storageAdapter.saveTemplate(feedbackSurveyTemplate);

  runApp(DynamicFormEngineExampleApp(storageAdapter: storageAdapter));
}

class DynamicFormEngineExampleApp extends StatefulWidget {
  final FormStorageAdapter storageAdapter;

  const DynamicFormEngineExampleApp({super.key, required this.storageAdapter});

  @override
  State<DynamicFormEngineExampleApp> createState() =>
      _DynamicFormEngineExampleAppState();
}

class _DynamicFormEngineExampleAppState
    extends State<DynamicFormEngineExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Form Engine Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.dark,
        ),
      ),
      home: ShowcaseHomeScreen(
        storageAdapter: widget.storageAdapter,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class ShowcaseHomeScreen extends StatefulWidget {
  final FormStorageAdapter storageAdapter;
  final VoidCallback onToggleTheme;

  const ShowcaseHomeScreen({
    super.key,
    required this.storageAdapter,
    required this.onToggleTheme,
  });

  @override
  State<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends State<ShowcaseHomeScreen> {
  int _selectedIndex = 0;
  FormTemplate? _selectedTemplate;
  FormSubmission? _activeSubmission;
  List<FormTemplate> _availableTemplates = [];
  List<FormSubmission> _recentSubmissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final templates = await widget.storageAdapter.getTemplates();
    final currentId = _selectedTemplate?.id;
    final activeTmpl = templates.where((t) => t.id == currentId).firstOrNull ??
        (templates.isNotEmpty ? templates.first : null);
    List<FormSubmission> subs = [];
    if (activeTmpl != null) {
      subs = await widget.storageAdapter.querySubmissions(formId: activeTmpl.id);
    }

    if (mounted) {
      setState(() {
        _availableTemplates = templates;
        _selectedTemplate = activeTmpl;
        _recentSubmissions = subs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.dynamic_form_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Dynamic Form Engine Showcase'),
          ],
        ),
        actions: [
          if (_availableTemplates.length > 1)
            DropdownButton<String>(
              value: _selectedTemplate?.id,
              underline: const SizedBox.shrink(),
              items: _availableTemplates.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text(t.name),
                );
              }).toList(),
              onChanged: (id) async {
                if (id != null) {
                  final found =
                      _availableTemplates.where((t) => t.id == id).firstOrNull;
                  if (found != null) {
                    final subs = await widget.storageAdapter
                        .querySubmissions(formId: found.id);
                    setState(() {
                      _selectedTemplate = found;
                      _recentSubmissions = subs;
                      _activeSubmission = null;
                    });
                  }
                }
              },
            ),
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                  extended: isWide,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.edit_note_rounded),
                      label: Text('Fill Form'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.build_circle_outlined),
                      label: Text('Form Designer'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_rounded),
                      label: Text('Submissions'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildFillView(context),
                      _buildCreatorView(context),
                      _buildSubmissionsView(context),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFillView(BuildContext context) {
    if (_selectedTemplate == null) {
      return const Center(child: Text('No form templates found.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= 900;

        Widget fillView = DynamicFormFillView(
          key: ValueKey(_selectedTemplate!.id),
          template: _selectedTemplate!,
          storageAdapter: widget.storageAdapter,
          registry: createFunctionalExampleRegistry(),
          onSubmitted: (submission) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Form submitted successfully! (ID: ${submission.id.substring(0, 8)})',
                ),
              ),
            );
            _reload();
            setState(() {
              _activeSubmission = submission;
              _selectedIndex = 2; // Jump to submissions tab
            });
          },
          onError: (err) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err), backgroundColor: Colors.red),
            );
          },
        );

        if (!isSplit) {
          return fillView;
        }

        return Row(
          children: [
            Expanded(flex: 3, child: fillView),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Structure (JSON)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ')
                              .convert(_selectedTemplate!.toMap()),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreatorView(BuildContext context) {
    return DynamicFormCreatorView(
      storageAdapter: widget.storageAdapter,
      onSaved: (newTmpl) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "${newTmpl.name}" saved!')),
        );
        _reload();
        setState(() {
          _selectedTemplate = newTmpl;
          _selectedIndex = 0;
        });
      },
    );
  }

  Widget _buildSubmissionsView(BuildContext context) {
    final theme = Theme.of(context);

    if (_activeSubmission != null && _selectedTemplate != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _activeSubmission = null),
                ),
                const SizedBox(width: 8),
                Text(
                  'Submission: ${_activeSubmission!.id}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: DynamicSubmissionDetailView(
              template: _selectedTemplate!,
              submission: _activeSubmission!,
            ),
          ),
        ],
      );
    }

    if (_recentSubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            const Text('No submissions recorded yet for this form.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: const Text('Fill Out This Form'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentSubmissions.length,
      itemBuilder: (context, index) {
        final sub = _recentSubmissions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.receipt_long_rounded,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text('Submission #${sub.id.substring(0, 8)}'),
            subtitle: Text(
              'Answers: ${sub.answers.length} fields • ${sub.submittedAt.toLocal()}',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              setState(() => _activeSubmission = sub);
            },
          ),
        );
      },
    );
  }
}
