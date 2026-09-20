// ignore_for_file: constant_identifier_names

/// All supported field types in the dynamic form engine.
enum FormFieldType {
  text,
  textarea,
  number,
  decimal,
  currency,
  email,
  phone,
  dropdown,
  radio,
  checkbox,
  multiSelect,
  toggle,
  date,
  time,
  dateTime,
  dateRange,
  image,
  video,
  document,
  signature,
  gps,
  gpsLocation,
  barcodeScanner,
  calculated,
  dynamicFieldGroup,
  groupRepeater;

  /// Helper to map string or legacy representation to [FormFieldType]
  static FormFieldType fromString(String value) {
    final lower = value.trim().toLowerCase();
    for (final type in FormFieldType.values) {
      if (type.name.toLowerCase() == lower) return type;
    }
    // Backward compatibility aliases
    if (lower == 'gps' || lower == 'location') return FormFieldType.gpsLocation;
    if (lower == 'dynamicfieldgroup' || lower == 'dynamic_field_group') {
      return FormFieldType.groupRepeater;
    }
    if (lower == 'multiselect' || lower == 'multi_select') {
      return FormFieldType.multiSelect;
    }
    return FormFieldType.text;
  }
}

/// Scope configuration for multi-tenant or contextual form assignment.
enum FormScopeType {
  global,
  contextRequired,
  contextOptional,
}

/// Enterprise form scoping governance.
enum FormScope {
  GLOBAL_MANDATORY,
  GLOBAL_OPTIONAL,
  CONTEXT_SPECIFIC,
}

/// Submission lifecycle status.
enum SubmissionStatus {
  draft,
  submitted,
  synced,
}

/// Outbox mutation operations.
enum SyncOperationType {
  insert,
  update,
  delete,
}
