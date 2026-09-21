import 'package:flutter/material.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_enums.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Default renderer for image, video, and document media attachment fields.
class MediaFieldRenderer extends StatelessWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;
  final Future<String?> Function(BuildContext context, FormFieldDefinition field)? onPickMedia;

  const MediaFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
    this.onPickMedia,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final error = controller.getError(field.id) ?? controller.getError(field.key);
    final isReadOnly = field.isReadOnly || controller.readOnly;

    final rawVal = controller.getAnswer(field.id) ?? controller.getAnswer(field.key);
    final currentVal = rawVal?.toString() ?? '';

    IconData iconData = Icons.attach_file_rounded;
    String actionLabel = 'Attach Document';
    if (field.fieldType == FormFieldType.image || field.fieldType == FormFieldType.media) {
      iconData = Icons.photo_camera_rounded;
      actionLabel = 'Attach Image';
    } else if (field.fieldType == FormFieldType.video) {
      iconData = Icons.videocam_rounded;
      actionLabel = 'Attach Video';
    }

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(formTheme.borderRadius),
              border: Border.all(
                color: error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: currentVal.isEmpty
                ? Center(
                    child: TextButton.icon(
                      onPressed: isReadOnly
                          ? null
                          : () => _handlePick(context, currentVal),
                      icon: Icon(iconData, color: theme.colorScheme.primary),
                      label: Text(
                        actionLabel,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, color: theme.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentVal.split('/').last.split('\\').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              currentVal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isReadOnly) ...[
                        IconButton(
                          icon: Icon(Icons.edit_rounded,
                              size: 18, color: theme.colorScheme.primary),
                          tooltip: 'Choose media',
                          onPressed: () => _handlePick(context, currentVal),
                        ),
                        IconButton(
                          icon: Icon(Icons.link_rounded,
                              size: 18, color: theme.colorScheme.onSurfaceVariant),
                          tooltip: 'Enter URL or path manually',
                          onPressed: () => _promptMediaInput(context, currentVal),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: theme.colorScheme.error),
                          tooltip: 'Remove',
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

  Future<void> _handlePick(BuildContext context, String currentVal) async {
    if (onPickMedia != null) {
      final res = await onPickMedia!(context, field);
      if (res != null && res.isNotEmpty) {
        controller.updateAnswerAndRecalculate(field.id, res);
      }
      return;
    }
    if (context.mounted) {
      await _promptMediaInput(context, currentVal);
    }
  }

  Future<void> _promptMediaInput(BuildContext context, String currentVal) async {
    final textController = TextEditingController(text: currentVal);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(field.label),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              labelText: 'Media Path or URL',
              hintText: 'Enter local file path or cloud URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
              child: const Text('Save'),
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
