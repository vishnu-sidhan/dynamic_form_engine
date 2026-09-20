import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/models/form_field_definition.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Default renderer for nested repeating dynamic field groups / sub-forms.
class GroupRepeaterFieldRenderer extends StatefulWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;

  const GroupRepeaterFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  State<GroupRepeaterFieldRenderer> createState() =>
      _GroupRepeaterFieldRendererState();
}

class _GroupRepeaterFieldRendererState extends State<GroupRepeaterFieldRenderer> {
  List<Map<String, String>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  void _loadRows() {
    final raw = widget.controller.getAnswer(widget.field.id) ??
        widget.controller.getAnswer(widget.field.key);
    if (raw is List) {
      _rows = raw
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v.toString())))
          .toList();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _rows = decoded
              .whereType<Map>()
              .map((m) => m.map((k, v) => MapEntry(k.toString(), v.toString())))
              .toList();
        }
      } catch (_) {}
    }
  }

  void _saveRows() {
    widget.controller.updateAnswerAndRecalculate(
      widget.field.id,
      jsonEncode(_rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final isReadOnly = widget.field.isReadOnly || widget.controller.readOnly;

    return Padding(
      padding: formTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.field.label, style: formTheme.sectionHeaderStyle),
              if (!isReadOnly)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _rows.add({});
                    });
                    _saveRows();
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Add Entry'),
                ),
            ],
          ),
          if (widget.field.hint != null && widget.field.hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(widget.field.hint!, style: formTheme.fieldHintStyle),
            ),
          if (_rows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(formTheme.borderRadius),
              ),
              child: Text(
                'No entries added yet',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            ..._rows.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(formTheme.borderRadius),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Entry #${idx + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (!isReadOnly)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            onPressed: () {
                              setState(() {
                                _rows.removeAt(idx);
                              });
                              _saveRows();
                            },
                          ),
                      ],
                    ),
                    TextFormField(
                      initialValue: row['value'] ?? '',
                      readOnly: isReadOnly,
                      decoration: (formTheme.inputDecoration ?? const InputDecoration())
                          .copyWith(
                        hintText: 'Entry details',
                      ),
                      onChanged: (val) {
                        row['value'] = val;
                        _saveRows();
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
