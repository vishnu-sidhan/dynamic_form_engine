import 'package:flutter/material.dart';
import '../../core/models/form_field_definition.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Default renderer for dynamically calculated read-only fields.
class CalculatedFieldRenderer extends StatelessWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;

  const CalculatedFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final rawVal = controller.getAnswer(field.id) ?? controller.getAnswer(field.key);
    final displayValue = rawVal?.toString().isNotEmpty == true
        ? rawVal.toString()
        : '0.00';

    return Padding(
      padding: formTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.label, style: formTheme.fieldLabelStyle),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Calculated',
                      style: formTheme.calculatedBadgeStyle,
                    ),
                  ],
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: formTheme.calculatedFieldBackgroundColor ??
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(formTheme.borderRadius),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
