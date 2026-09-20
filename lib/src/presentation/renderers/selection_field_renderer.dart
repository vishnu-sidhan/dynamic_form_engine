// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_enums.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Default renderer for single-select dropdown, radio buttons, checkboxes, multi-select, and switches.
class SelectionFieldRenderer extends StatefulWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;

  const SelectionFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  State<SelectionFieldRenderer> createState() => _SelectionFieldRendererState();
}

class _SelectionFieldRendererState extends State<SelectionFieldRenderer> {
  List<FormOption> _resolvedOptions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    if (widget.field.referenceTarget != null &&
        widget.field.referenceTarget!.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final options = await widget.controller.optionResolver.resolveOptions(
          referenceTarget: widget.field.referenceTarget!,
          contextId: widget.controller.template.contextScope,
          metadata: widget.field.metadata,
        );
        if (mounted) {
          setState(() {
            _resolvedOptions = options;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      _resolvedOptions = widget.field.options;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final error = widget.controller.getError(widget.field.id) ??
        widget.controller.getError(widget.field.key);
    final isReadOnly = widget.field.isReadOnly || widget.controller.readOnly;

    final rawVal = widget.controller.getAnswer(widget.field.id) ??
        widget.controller.getAnswer(widget.field.key);
    final currentVal = rawVal?.toString() ?? '';

    Widget content;

    if (_isLoading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else {
      switch (widget.field.fieldType) {
        case FormFieldType.checkbox:
          final isChecked = currentVal == 'true' ||
              currentVal == 'yes' ||
              currentVal == '1' ||
              currentVal == 'checked';
          content = CheckboxListTile(
            title: Text(widget.field.label, style: formTheme.fieldLabelStyle),
            subtitle: widget.field.hint != null ? Text(widget.field.hint!) : null,
            value: isChecked,
            contentPadding: EdgeInsets.zero,
            activeColor: theme.colorScheme.primary,
            onChanged: isReadOnly
                ? null
                : (val) {
                    widget.controller.updateAnswerAndRecalculate(
                      widget.field.id,
                      (val ?? false).toString(),
                    );
                  },
          );
          break;

        case FormFieldType.toggle:
          final isToggled = currentVal == 'true' ||
              currentVal == 'yes' ||
              currentVal == '1';
          content = SwitchListTile(
            title: Text(widget.field.label, style: formTheme.fieldLabelStyle),
            subtitle: widget.field.hint != null ? Text(widget.field.hint!) : null,
            value: isToggled,
            contentPadding: EdgeInsets.zero,
            activeColor: theme.colorScheme.primary,
            onChanged: isReadOnly
                ? null
                : (val) {
                    widget.controller.updateAnswerAndRecalculate(
                      widget.field.id,
                      val.toString(),
                    );
                  },
          );
          break;

        case FormFieldType.radio:
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _resolvedOptions.map((opt) {
              return RadioListTile<String>(
                title: Text(opt.label, style: theme.textTheme.bodyMedium),
                value: opt.value,
                groupValue: currentVal,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
                onChanged: isReadOnly
                    ? null
                    : (val) {
                        if (val != null) {
                          widget.controller.updateAnswerAndRecalculate(
                            widget.field.id,
                            val,
                          );
                        }
                      },
              );
            }).toList(),
          );
          break;

        case FormFieldType.multiSelect:
          final List<String> selectedValues = currentVal.isEmpty
              ? []
              : currentVal.split(',').map((s) => s.trim()).toList();
          content = Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _resolvedOptions.map((opt) {
              final isSelected = selectedValues.contains(opt.value);
              return FilterChip(
                label: Text(opt.label),
                selected: isSelected,
                selectedColor: theme.colorScheme.primaryContainer,
                onSelected: isReadOnly
                    ? null
                    : (sel) {
                        final updated = List<String>.from(selectedValues);
                        if (sel) {
                          updated.add(opt.value);
                        } else {
                          updated.remove(opt.value);
                        }
                        widget.controller.updateAnswerAndRecalculate(
                          widget.field.id,
                          updated.join(','),
                        );
                      },
              );
            }).toList(),
          );
          break;

        case FormFieldType.dropdown:
        default:
          final matchingOpt = _resolvedOptions.any((o) => o.value == currentVal)
              ? currentVal
              : null;
          content = DropdownButtonFormField<String>(
            value: matchingOpt,
            decoration: (formTheme.inputDecoration ?? const InputDecoration())
                .copyWith(
              hintText: widget.field.hint ?? 'Select an option',
              errorText: error,
            ),
            isExpanded: true,
            items: _resolvedOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt.value,
                child: Text(
                  opt.label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: isReadOnly
                ? null
                : (val) {
                    if (val != null) {
                      widget.controller.updateAnswerAndRecalculate(
                        widget.field.id,
                        val,
                      );
                    }
                  },
          );
          break;
      }
    }

    if (widget.field.fieldType == FormFieldType.checkbox ||
        widget.field.fieldType == FormFieldType.toggle) {
      return Padding(
        padding: formTheme.fieldPadding,
        child: content,
      );
    }

    return Padding(
      padding: formTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.field.label,
                style: formTheme.fieldLabelStyle,
              ),
              if (widget.field.isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (widget.field.hint != null && widget.field.hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
              child: Text(
                widget.field.hint!,
                style: formTheme.fieldHintStyle,
              ),
            ),
          const SizedBox(height: 6),
          content,
          if (error != null && widget.field.fieldType != FormFieldType.dropdown)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 12.0),
              child: Text(
                error,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
