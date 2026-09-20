# Dynamic Form Engine

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web%20|%20macOS%20|%20Windows%20|%20Linux-brightgreen.svg)]()

A pluggable, database-agnostic, offline-first **Dynamic Form Engine** for Flutter. Build, validate, evaluate formulas, render, and submit dynamic forms with rich conditional visibility, outbox synchronization, and customizable UI slot builders.

---

## Features

- 📱 **Offline-First & Database Agnostic**: Clean SPI contract (`FormStorageAdapter`) with a ready-to-use local NoSQL implementation (`DefaultSembastStorageAdapter`) and offline outbox mutation tracking (`OutboxMutation`).
- ⚡ **Real-Time Dynamic Formula Evaluation**: Embedded mathematical expression parser (`FormulaEvaluator`) supporting token replacement (`[quantity] * [unit_price]`), operator precedence (`+`, `-`, `*`, `/`, `()`), and division-by-zero protection.
- 👁️ **Conditional Visibility**: Reactive dependency graph showing or hiding fields based on dependent values (`dependsOnFieldKey` and `showIfValue`).
- 🛡️ **Comprehensive Validation Engine**: Multi-constraint field validation (`FieldValidator`) for required fields, min/max string lengths, numeric ranges, regex patterns, and custom validator functions.
- 🎨 **16+ Built-in Field Types**:
  - **Inputs**: `text`, `textarea`, `number`, `decimal`
  - **Selection**: `dropdown`, `radio`, `checkbox`, `multiSelect`
  - **Temporal**: `date`, `time`, `dateTime`
  - **Advanced**: `calculated`, `gpsLocation`, `signature`, `photo`, `groupRepeater`
- 🧩 **Pluggable Architecture (SPI)**:
  - `FormStorageAdapter`: Swap storage engines (Sembast, SQLite/Drift, Hive, Isar, Cloud Firestore).
  - `FormOptionResolver`: Asynchronously resolve dynamic dropdown options from remote APIs or databases.
  - `FormSubmissionInterceptor`: Pre-submission middleware pipeline to enrich, sanitize, or audit data.
  - `FormSyncDelegate`: Pluggable background synchronizer for backend APIs.
- 🎛️ **Ready-to-Use UI Views & Customization**:
  - `DynamicFormFillView`: Plug-and-play reactive form renderer with custom header, wrapper, and submit button slots.
  - `DynamicFormCreatorView`: Interactive visual form builder to construct and configure form templates.
  - `DynamicSubmissionDetailView`: Structured submission inspection view.
  - `FieldRendererRegistry`: Override existing field widgets or register completely custom renderers.
  - `FormThemeData`: Deeply customizable design system supporting dynamic Material 3 theming.

---

## Architecture

```text
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   DynamicFormFillView  |  DynamicFormCreatorView       │
│   DynamicSubmissionDetailView  |  FormFlowController   │
│   FieldRendererRegistry  <-- Built-in & Custom Widgets │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                    Business Engines                    │
│   FormulaEvaluator  |  FieldValidator  |  FormTheme   │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│            Core Contracts (SPI) & Models               │
│   FormStorageAdapter  |  FormOptionResolver            │
│   FormSubmissionInterceptor  |  FormSyncDelegate       │
│   FormTemplate  |  FormFieldDefinition  | Submission   │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                   Storage Adapters                     │
│   DefaultSembastStorageAdapter  |  Custom Adapters     │
└────────────────────────────────────────────────────────┘
```

---

## Getting Started

### Installation

Add `dynamic_form_engine` to your `pubspec.yaml`:

```yaml
dependencies:
  dynamic_form_engine:
    # If using local path
    path: ../dynamic_form_engine
    # Or git reference:
    # git:
    #   url: https://github.com/your-repo/dynamic_form_engine.git
```

Run `flutter pub get`.

---

## Usage Guide

### 1. Initialize Storage & Seed a Template

```dart
import 'package:flutter/material.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage adapter (e.g., Sembast embedded database)
  final storageAdapter = DefaultSembastStorageAdapter();
  await storageAdapter.initialize();

  // Create or load a template
  final template = FormTemplate(
    id: 'work_order',
    name: 'Work Order & Inspection',
    description: 'Service dispatch and QA inspection report',
    createdAt: DateTime.now(),
    fields: const [
      FormFieldDefinition(
        id: 'service_type',
        formId: 'work_order',
        key: 'service_type',
        label: 'Service Category',
        fieldType: FormFieldType.dropdown,
        isRequired: true,
        options: [
          FormOption(label: 'Standard Maintenance', value: 'standard'),
          FormOption(label: 'Priority SLA Repair', value: 'priority'),
          FormOption(label: 'Full System Audit', value: 'audit'),
        ],
      ),
      FormFieldDefinition(
        id: 'hours_billed',
        formId: 'work_order',
        key: 'hours_billed',
        label: 'Labor Hours',
        fieldType: FormFieldType.number,
        isRequired: true,
        min: 1,
      ),
      FormFieldDefinition(
        id: 'hourly_rate',
        formId: 'work_order',
        key: 'hourly_rate',
        label: 'Hourly Rate ($)',
        fieldType: FormFieldType.decimal,
        isRequired: true,
        min: 10.0,
      ),
      FormFieldDefinition(
        id: 'total_fee',
        formId: 'work_order',
        key: 'total_fee',
        label: 'Estimated Fee ($)',
        fieldType: FormFieldType.calculated,
        calculationFormula: '[hours_billed] * [hourly_rate]',
      ),
      FormFieldDefinition(
        id: 'has_defect',
        formId: 'work_order',
        key: 'has_defect',
        label: 'Flag Critical Issues / Defect?',
        fieldType: FormFieldType.checkbox,
      ),
      FormFieldDefinition(
        id: 'defect_notes',
        formId: 'work_order',
        key: 'defect_notes',
        label: 'Issue Details & Root Cause',
        fieldType: FormFieldType.textarea,
        dependsOnFieldKey: 'has_defect',
        showIfValue: 'true',
        isRequired: true,
      ),
    ],
  );

  await storageAdapter.saveTemplate(template);

  runApp(MyApp(storageAdapter: storageAdapter, template: template));
}
```

### 2. Render and Fill a Dynamic Form

Use `DynamicFormFillView` to present the form to the user:

```dart
class FormPage extends StatelessWidget {
  final FormStorageAdapter storageAdapter;
  final FormTemplate template;

  const FormPage({
    super.key,
    required this.storageAdapter,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: DynamicFormFillView(
        template: template,
        storageAdapter: storageAdapter,
        onSubmitted: (submission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved submission: ${submission.id}')),
          );
        },
        onError: (errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        },
      ),
    );
  }
}
```

### 3. Visual Form Designer (`DynamicFormCreatorView`)

Allow administrators or end users to build dynamic forms interactively:

```dart
DynamicFormCreatorView(
  storageAdapter: storageAdapter,
  onSaved: (FormTemplate newTemplate) {
    print('Template created with ${newTemplate.fields.length} fields!');
  },
)
```

### 4. Submission Details Inspection (`DynamicSubmissionDetailView`)

Render submitted answers in a structured format:

```dart
DynamicSubmissionDetailView(
  template: template,
  submission: submission,
)
```

### 5. Custom Field Renderers

Register your own widget renderer for any field type:

```dart
final registry = FieldRendererRegistry.withDefaults();

// Override or add a custom renderer
registry.register(
  FormFieldType.signature,
  CustomSignatureRenderer(),
);

DynamicFormFillView(
  template: template,
  registry: registry,
);
```

### 6. Dynamic Option Resolvers

Resolve dropdown options dynamically from an API:

```dart
class RemoteApiOptionResolver implements FormOptionResolver {
  @override
  Future<List<FormOption>> resolveOptions(
    FormFieldDefinition field,
    Map<String, dynamic> currentAnswers,
  ) async {
    if (field.key == 'warehouse_id') {
      final warehouses = await fetchWarehousesFromApi();
      return warehouses
          .map((w) => FormOption(label: w.name, value: w.id))
          .toList();
    }
    return field.options;
  }
}
```

### 7. Pre-Submission Interceptors

Validate business rules or inject audit metadata before saving:

```dart
class AuditInterceptor implements FormSubmissionInterceptor {
  @override
  Future<FormSubmission> intercept(
    FormSubmission submission,
    FormTemplate template,
  ) async {
    final updatedAnswers = Map<String, dynamic>.from(submission.answers);
    updatedAnswers['_submitted_by'] = 'current_user_uuid';
    updatedAnswers['_device_locale'] = 'en_US';

    return submission.copyWith(answers: updatedAnswers);
  }
}
```

---

## Running the Showcase / Example App

The project includes an interactive showcase application in `example/lib/main.dart` with:
- **All Field Types Master Showcase**: Demonstrates every supported field type (text, number, decimal, currency, email, phone, dropdown, radio, checkbox, multi-select, toggle, date, time, date-time, date-range, image, video, document, signature, GPS coordinates, calculated formulas, and nested group repeaters).
- **Work Order & Service Inspection**: Dynamic formulas (`[hours_billed] * [hourly_rate]`), conditional escalation triggers, GPS location, and inspector signature.
- **Customer Feedback & Satisfaction Survey**: Ratings, multi-choice features, satisfaction toggles, and feedback text.
- **Visual Form Designer**: Interactive visual builder to create, edit, and persist new form templates.
- **Submissions Viewer**: Tabular history and structured answer inspection.
- **Live JSON Inspector**: Real-time serialization preview.
- **Dark & Light Mode Switcher**: Material 3 theme toggle.

### Run in VS Code
1. Open this repository in Visual Studio Code.
2. Select the **Run and Debug** tab (`Ctrl+Shift+D` / `Cmd+Shift+D`).
3. Select **Run Example App** from the configuration dropdown.
4. Press **F5** (or click the green Play button).

### Run via Terminal
```bash
cd example
flutter run -d chrome # Or: macos, ios, android, windows, linux
```

---

## Testing

Run all unit and widget tests:

```bash
flutter test
```

Current test suites cover:
- `formula_evaluator_test.dart`: Mathematical token expressions, arithmetic precedence, and division-by-zero safety.
- `conditional_visibility_test.dart`: Parent field dependencies and visibility graph transitions.
- `field_validator_test.dart`: Multi-type validation constraints, min/max rules, and regex formats.
- `form_flow_controller_test.dart`: End-to-end form state management, live recalculations, and submission pipeline.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
