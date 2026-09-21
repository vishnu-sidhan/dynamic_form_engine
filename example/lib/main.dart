import 'package:flutter/material.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';
import 'presentation/views/home_catalog_screen.dart';
import 'services/persistent_storage_service.dart';
import 'services/example_platform_handlers.dart';
import 'services/backup/form_backup_manager.dart';
import 'services/backup/form_media_bundle_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerExamplePlatformHandlers();

  final storageAdapter = PersistentStorageService();
  await storageAdapter.initialize();

  // 1. Comprehensive Master Form using ALL supported field types in the package
  const masterShowcaseTemplate = FormTemplate(
    id: 'master_field_showcase',
    title: 'All Field Types Master Showcase',
    description:
        'Comprehensive showcase demonstrating every supported field type: text, textarea, email, phone, number, decimal, currency, math formula, dropdown, radio, multi-select, toggle, checkbox, date, time, dateTime, dateRange, GPS location, media/photo, video, document, signature, barcode/QR scanner, and nested group repeater.',
    version: 1,
    fields: [
      FormFieldDefinition(
        id: 'full_name',
        label: 'Full Name',
        type: FormFieldType.text,
        hint: 'Enter your full name',
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'contact_email',
        label: 'Email Address',
        type: FormFieldType.email,
        hint: 'alex@example.com',
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'contact_phone',
        label: 'Phone Number',
        type: FormFieldType.phone,
        hint: '+1 (555) 019-2834',
      ),
      FormFieldDefinition(
        id: 'project_narrative',
        label: 'Detailed Project Scope & Notes',
        type: FormFieldType.textarea,
        hint: 'Outline requirements, observations, and notes',
      ),
      FormFieldDefinition(
        id: 'quantity_units',
        label: 'Quantity Units',
        type: FormFieldType.number,
        hint: 'Number of units',
        isRequired: true,
        min: 1,
      ),
      FormFieldDefinition(
        id: 'unit_rate',
        label: 'Unit Rate (\$)',
        type: FormFieldType.decimal,
        hint: 'Price per unit in USD',
        isRequired: true,
        min: 0.5,
      ),
      FormFieldDefinition(
        id: 'allocated_budget',
        label: 'Allocated Budget (\$)',
        type: FormFieldType.currency,
        hint: 'Approved budget cap',
      ),
      FormFieldDefinition(
        id: 'computed_subtotal',
        label: 'Calculated Subtotal (\$)',
        type: FormFieldType.calculated,
        hint: 'Dynamic math formula: [quantity_units] * [unit_rate]',
        calculationFormula: '[quantity_units] * [unit_rate]',
      ),
      FormFieldDefinition(
        id: 'department',
        label: 'Assigned Department',
        type: FormFieldType.dropdown,
        hint: 'Select the responsible department',
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
        label: 'Priority Level',
        type: FormFieldType.radio,
        options: [
          FormOption(label: 'Low (P3)', value: 'low'),
          FormOption(label: 'Standard (P2)', value: 'standard'),
          FormOption(label: 'High (P1)', value: 'high'),
          FormOption(label: 'Critical Urgent (P0)', value: 'critical'),
        ],
      ),
      FormFieldDefinition(
        id: 'subscribed_modules',
        label: 'Enabled Modules & Features',
        type: FormFieldType.multiSelect,
        options: [
          FormOption(label: 'Identity & Access Management', value: 'iam'),
          FormOption(label: 'Real-time Telemetry', value: 'telemetry'),
          FormOption(label: 'Automated CI/CD Workflows', value: 'cicd'),
          FormOption(label: 'Compliance & Audit Loggers', value: 'audit'),
        ],
      ),
      FormFieldDefinition(
        id: 'enable_notifications',
        label: 'Enable Automated Alerts & Push Notifications',
        type: FormFieldType.toggle,
      ),
      FormFieldDefinition(
        id: 'terms_accepted',
        label: 'I accept the Enterprise Service Terms and Data Privacy Policy',
        type: FormFieldType.checkbox,
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'target_delivery_date',
        label: 'Target Delivery Date',
        type: FormFieldType.date,
      ),
      FormFieldDefinition(
        id: 'sync_time',
        label: 'Daily Standup Time',
        type: FormFieldType.time,
      ),
      FormFieldDefinition(
        id: 'inspection_timestamp',
        label: 'Inspection Timestamp',
        type: FormFieldType.dateTime,
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'sprint_period',
        label: 'Sprint Execution Period',
        type: FormFieldType.dateRange,
      ),
      FormFieldDefinition(
        id: 'site_geotag',
        label: 'GPS Facility Coordinates',
        type: FormFieldType.location,
        hint: 'Capture physical GPS coordinates',
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'site_photo',
        label: 'Attachment / Site Photo',
        type: FormFieldType.media,
      ),
      FormFieldDefinition(
        id: 'video_recording',
        label: 'Walkthrough Video Recording',
        type: FormFieldType.video,
      ),
      FormFieldDefinition(
        id: 'spec_document',
        label: 'Technical Specification PDF / Document',
        type: FormFieldType.document,
      ),
      FormFieldDefinition(
        id: 'barcode_tag',
        label: 'Asset Barcode / QR Code Scanner',
        type: FormFieldType.barcodeScanner,
        hint: 'Scan or enter asset barcode',
      ),
      FormFieldDefinition(
        id: 'signoff_signature',
        label: 'Authorized Sign-Off Signature',
        type: FormFieldType.signature,
        hint: 'Sign directly on the canvas pad',
      ),
      FormFieldDefinition(
        id: 'line_item_repeater',
        label: 'Deliverable Line Items',
        type: FormFieldType.groupRepeater,
        hint: 'Add repeating deliverables',
      ),
    ],
  );

  // 2. Site Safety Inspection Form
  const siteInspectionTemplate = FormTemplate(
    id: 'inspection_site_v1',
    title: 'Site Safety Inspection',
    description: 'Routine site validation, machinery status, and safety checks.',
    version: 1,
    fields: [
      FormFieldDefinition(
        id: 'inspector_name',
        type: FormFieldType.text,
        label: 'Inspector Name',
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'inspection_date',
        type: FormFieldType.dateTime,
        label: 'Inspection Timestamp',
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'location_coords',
        type: FormFieldType.location,
        label: 'GPS Location',
        isRequired: true,
      ),
      FormFieldDefinition(
        id: 'site_photo',
        type: FormFieldType.media,
        label: 'Attachment / Site Photo',
      ),
    ],
  );

  // Seed forms if not already present in storage
  final existingShowcase =
      await storageAdapter.getTemplate('master_field_showcase');
  if (existingShowcase == null) {
    await storageAdapter.saveTemplate(masterShowcaseTemplate);
  }

  final existingInspection =
      await storageAdapter.getTemplate('inspection_site_v1');
  if (existingInspection == null) {
    await storageAdapter.saveTemplate(siteInspectionTemplate);
  }

  final bundleService = FormMediaBundleService(storageAdapter: storageAdapter);
  final backupManager = FormBackupManager(bundleService: bundleService);

  runApp(DynamicFormExampleApp(
    storageAdapter: storageAdapter,
    backupManager: backupManager,
  ));
}

class DynamicFormExampleApp extends StatelessWidget {
  final FormStorageAdapter storageAdapter;
  final FormBackupManager? backupManager;

  const DynamicFormExampleApp({
    super.key,
    required this.storageAdapter,
    this.backupManager,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Form Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF135D66), // Matches DF outline teal
      ),
      home: HomeCatalogScreen(
        storageAdapter: storageAdapter,
        backupManager: backupManager,
      ),
    );
  }
}

/// Backwards compatibility alias for tests
typedef DynamicFormEngineExampleApp = DynamicFormExampleApp;
