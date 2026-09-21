import 'package:flutter/material.dart';
import '../../core/models/form_field_definition.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Default renderer for GPS location coordinate capture.
class LocationFieldRenderer extends StatelessWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;
  final Future<String?> Function(BuildContext context, FormFieldDefinition field)? onCaptureLocation;

  const LocationFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
    this.onCaptureLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final error = controller.getError(field.id) ?? controller.getError(field.key);
    final isReadOnly = field.isReadOnly || controller.readOnly;

    final rawVal = controller.getAnswer(field.id) ?? controller.getAnswer(field.key);
    final currentVal = rawVal?.toString() ?? '';

    return Padding(
      padding: formTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.label, style: formTheme.fieldLabelStyle),
              if (field.isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (field.hint != null && field.hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
              child: Text(field.hint!, style: formTheme.fieldHintStyle),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(formTheme.borderRadius),
              border: Border.all(
                color: error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentVal.isNotEmpty
                        ? currentVal
                        : 'No coordinates recorded',
                    style: currentVal.isNotEmpty
                        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
                        : theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                  ),
                ),
                if (!isReadOnly) ...[
                  FilledButton.tonalIcon(
                    onPressed: () => _handleCapture(context, currentVal),
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: Text(currentVal.isEmpty ? 'Capture' : 'Update'),
                  ),
                  if (onCaptureLocation != null)
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      tooltip: 'Enter coordinates manually',
                      onPressed: () => _promptCoordinates(context, currentVal),
                    ),
                  if (currentVal.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: theme.colorScheme.error),
                      tooltip: 'Clear coordinates',
                      onPressed: () =>
                          controller.updateAnswerAndRecalculate(field.id, ''),
                    ),
                ],
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 12.0),
              child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCapture(BuildContext context, String currentVal) async {
    if (onCaptureLocation != null) {
      final res = await onCaptureLocation!(context, field);
      if (res != null && res.isNotEmpty) {
        controller.updateAnswerAndRecalculate(field.id, res);
      }
      return;
    }
    if (context.mounted) {
      await _promptCoordinates(context, currentVal);
    }
  }

  Future<void> _promptCoordinates(BuildContext context, String currentVal) async {
    final textController = TextEditingController(text: currentVal);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(field.label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Latitude, Longitude',
                  hintText: 'e.g. 11.0168, 76.9558',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );

    if (res != null) {
      controller.updateAnswerAndRecalculate(field.id, res);
    }
  }
}
