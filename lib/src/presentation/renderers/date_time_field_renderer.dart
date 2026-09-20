import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_enums.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Default renderer for date, time, dateTime, and dateRange fields.
class DateTimeFieldRenderer extends StatelessWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;

  const DateTimeFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final error = controller.getError(field.id) ?? controller.getError(field.key);
    final isReadOnly = field.isReadOnly || controller.readOnly;

    final rawVal = controller.getAnswer(field.id) ?? controller.getAnswer(field.key);
    final currentVal = rawVal?.toString() ?? '';

    IconData iconData = Icons.calendar_today_rounded;
    if (field.fieldType == FormFieldType.time) {
      iconData = Icons.access_time_rounded;
    } else if (field.fieldType == FormFieldType.dateRange) {
      iconData = Icons.date_range_rounded;
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
          InkWell(
            borderRadius: BorderRadius.circular(formTheme.borderRadius),
            onTap: isReadOnly ? null : () => _pickDateTime(context, currentVal),
            child: InputDecorator(
              decoration: (formTheme.inputDecoration ?? const InputDecoration())
                  .copyWith(
                hintText: field.hint ?? 'Tap to select',
                errorText: error,
                suffixIcon: Icon(iconData, color: theme.colorScheme.primary),
              ),
              child: Text(
                currentVal.isNotEmpty ? currentVal : (field.hint ?? 'Tap to select'),
                style: currentVal.isNotEmpty
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context, String currentVal) async {
    final now = DateTime.now();

    if (field.fieldType == FormFieldType.time) {
      TimeOfDay initialTime = TimeOfDay.now();
      if (currentVal.isNotEmpty) {
        try {
          final parts = currentVal.split(':');
          if (parts.length >= 2) {
            initialTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (_) {}
      }
      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (picked != null) {
        final formatted =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        controller.updateAnswerAndRecalculate(field.id, formatted);
      }
      return;
    }

    if (field.fieldType == FormFieldType.dateRange) {
      DateTimeRange? initialRange;
      if (currentVal.contains(' - ')) {
        try {
          final parts = currentVal.split(' - ');
          initialRange = DateTimeRange(
            start: DateTime.parse(parts[0]),
            end: DateTime.parse(parts[1]),
          );
        } catch (_) {}
      }
      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: initialRange,
      );
      if (pickedRange != null) {
        final f = DateFormat('yyyy-MM-dd');
        final str = '${f.format(pickedRange.start)} - ${f.format(pickedRange.end)}';
        controller.updateAnswerAndRecalculate(field.id, str);
      }
      return;
    }

    // Single Date or DateTime
    DateTime initialDate = now;
    if (currentVal.isNotEmpty) {
      initialDate = DateTime.tryParse(currentVal) ?? now;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (field.fieldType == FormFieldType.dateTime) {
        if (!context.mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDate),
        );
        final finalDt = pickedTime != null
            ? DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              )
            : pickedDate;
        controller.updateAnswerAndRecalculate(
          field.id,
          finalDt.toIso8601String(),
        );
      } else {
        final formatted = DateFormat('yyyy-MM-dd').format(pickedDate);
        controller.updateAnswerAndRecalculate(field.id, formatted);
      }
    }
  }
}
