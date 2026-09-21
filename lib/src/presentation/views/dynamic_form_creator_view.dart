// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/form_template.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_enums.dart';
import '../../core/contracts/form_storage_adapter.dart';
import '../../core/theme/form_theme_data.dart';

/// Pluggable Form Builder / Creator View for visually designing and modifying form templates.
class DynamicFormCreatorView extends StatefulWidget {
  final FormTemplate? initialTemplate;
  final FormStorageAdapter? storageAdapter;
  final String? defaultContextScope;
  final void Function(FormTemplate template)? onSaved;
  final void Function(FormTemplate template)? onSave;
  final Widget Function(BuildContext context, VoidCallback onSave)? actionButtonsBuilder;

  const DynamicFormCreatorView({
    super.key,
    this.initialTemplate,
    this.storageAdapter,
    this.defaultContextScope,
    this.onSaved,
    this.onSave,
    this.actionButtonsBuilder,
  });

  @override
  State<DynamicFormCreatorView> createState() => _DynamicFormCreatorViewState();
}

class _DynamicFormCreatorViewState extends State<DynamicFormCreatorView> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final List<FormFieldDefinition> _fields;
  late String _formId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tmpl = widget.initialTemplate;
    _formId = tmpl?.id ?? const Uuid().v4();
    _nameController = TextEditingController(text: tmpl?.name ?? '');
    _descController = TextEditingController(text: tmpl?.description ?? '');
    _fields = tmpl != null ? List<FormFieldDefinition>.from(tmpl.fields) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a form title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedTemplate = FormTemplate(
        id: _formId,
        name: name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        contextScope: widget.initialTemplate?.contextScope ?? widget.defaultContextScope,
        isSystemLocked: widget.initialTemplate?.isSystemLocked ?? false,
        version: (widget.initialTemplate?.version ?? 0) + 1,
        createdAt: widget.initialTemplate?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        fields: _fields.asMap().entries.map((e) {
          return e.value.copyWith(formId: _formId, orderIndex: e.key);
        }).toList(),
      );

      if (widget.storageAdapter != null) {
        await widget.storageAdapter!.saveTemplate(updatedTemplate);
      }

      widget.onSaved?.call(updatedTemplate);
      widget.onSave?.call(updatedTemplate);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddFieldDialog([FormFieldDefinition? existingField, int? editIndex]) {
    final labelCtrl = TextEditingController(text: existingField?.label ?? '');
    final keyCtrl = TextEditingController(text: existingField?.key ?? '');
    final hintCtrl = TextEditingController(text: existingField?.hint ?? '');
    final optionsCtrl = TextEditingController(
      text: existingField?.options.map((o) => o.label).join(', ') ?? '',
    );
    final formulaCtrl = TextEditingController(
      text: existingField?.calculationFormula ?? '',
    );
    final dependsOnCtrl = TextEditingController(
      text: existingField?.dependsOnFieldKey ?? '',
    );
    final showIfCtrl = TextEditingController(
      text: existingField?.showIfValue ?? '',
    );

    FormFieldType selectedType = existingField?.fieldType ?? FormFieldType.text;
    bool isRequired = existingField?.isRequired ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text(existingField != null ? 'Edit Field' : 'Add Form Field'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(labelText: 'Field Label *'),
                      onChanged: (val) {
                        if (keyCtrl.text.isEmpty ||
                            keyCtrl.text ==
                                labelCtrl.text
                                    .toLowerCase()
                                    .replaceAll(RegExp(r'\s+'), '_')) {
                          keyCtrl.text =
                              val.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: keyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Field Key (Internal Identifier)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<FormFieldType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Field Type'),
                      items: FormFieldType.values.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hintCtrl,
                      decoration: const InputDecoration(labelText: 'Hint / Placeholder'),
                    ),
                    const SizedBox(height: 8),
                    if (selectedType == FormFieldType.dropdown ||
                        selectedType == FormFieldType.radio ||
                        selectedType == FormFieldType.multiSelect) ...[
                      TextField(
                        controller: optionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Options (comma-separated)',
                          hintText: 'Option 1, Option 2, Option 3',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (selectedType == FormFieldType.calculated) ...[
                      TextField(
                        controller: formulaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Formula Expression',
                          hintText: 'e.g. [quantity] * [unit_cost]',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: dependsOnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Depends On (Parent Field Key)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: showIfCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Show If (Expected Parent Value)',
                        hintText: 'e.g. yes, true, or specific value',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Required Field'),
                      value: isRequired,
                      contentPadding: EdgeInsets.zero,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) => setDialogState(() => isRequired = v ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final label = labelCtrl.text.trim();
                    if (label.isEmpty) return;

                    final opts = optionsCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .map((s) => FormOption(label: s, value: s))
                        .toList();

                    final newField = FormFieldDefinition(
                      id: existingField?.id ?? const Uuid().v4(),
                      formId: _formId,
                      key: keyCtrl.text.trim().isNotEmpty
                          ? keyCtrl.text.trim()
                          : label.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
                      label: label,
                      hint: hintCtrl.text.trim().isEmpty ? null : hintCtrl.text.trim(),
                      fieldType: selectedType,
                      isRequired: isRequired,
                      options: opts,
                      calculationFormula: formulaCtrl.text.trim().isEmpty
                          ? null
                          : formulaCtrl.text.trim(),
                      dependsOnFieldKey: dependsOnCtrl.text.trim().isEmpty
                          ? null
                          : dependsOnCtrl.text.trim(),
                      showIfValue: showIfCtrl.text.trim().isEmpty
                          ? null
                          : showIfCtrl.text.trim(),
                    );

                    setState(() {
                      if (editIndex != null) {
                        _fields[editIndex] = newField;
                      } else {
                        _fields.add(newField);
                      }
                    });

                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save Field'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Form Title
        TextFormField(
          controller: _nameController,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          decoration: (formTheme.inputDecoration ?? const InputDecoration()).copyWith(
            labelText: 'Form Title *',
            hintText: 'Enter form name',
          ),
        ),
        const SizedBox(height: 12),

        // Form Description
        TextFormField(
          controller: _descController,
          maxLines: 2,
          decoration: (formTheme.inputDecoration ?? const InputDecoration()).copyWith(
            labelText: 'Description (Optional)',
            hintText: 'Describe the purpose of this form',
          ),
        ),
        const SizedBox(height: 24),

        // Fields Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Form Fields (${_fields.length})',
              style: formTheme.sectionHeaderStyle,
            ),
            FilledButton.tonalIcon(
              onPressed: () => _showAddFieldDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Field'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fields List
        if (_fields.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(formTheme.borderRadius),
            ),
            child: Text(
              'No fields added yet. Tap "Add Field" to start.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fields.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _fields.removeAt(oldIndex);
                _fields.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final f = _fields[index];
              return Card(
                key: ValueKey(f.id),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(formTheme.borderRadius),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Type: ${f.fieldType.name}${f.isRequired ? ' • Required' : ''}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showAddFieldDialog(f, index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 20, color: theme.colorScheme.error),
                        onPressed: () {
                          setState(() => _fields.removeAt(index));
                        },
                      ),
                      const Icon(Icons.drag_handle_rounded),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 32),

        // Action Buttons Slot
        if (widget.actionButtonsBuilder != null)
          widget.actionButtonsBuilder!(context, _handleSave)
        else
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Template',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
      ],
    );
  }
}
