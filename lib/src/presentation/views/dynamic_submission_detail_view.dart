import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/form_template.dart';
import '../../core/models/form_submission.dart';
import '../../core/contracts/form_option_resolver.dart';
import '../../core/theme/form_theme_data.dart';

/// Pluggable Submission Detail View for reviewing filled form answers.
class DynamicSubmissionDetailView extends StatefulWidget {
  final FormTemplate template;
  final FormSubmission submission;
  final FormOptionResolver optionResolver;
  final Widget Function(BuildContext context, FormSubmission submission)? headerBuilder;
  final Widget Function(BuildContext context, FormSubmission submission)? footerBuilder;

  const DynamicSubmissionDetailView({
    super.key,
    required this.template,
    required this.submission,
    this.optionResolver = const DefaultFormOptionResolver(),
    this.headerBuilder,
    this.footerBuilder,
  });

  @override
  State<DynamicSubmissionDetailView> createState() =>
      _DynamicSubmissionDetailViewState();
}

class _DynamicSubmissionDetailViewState
    extends State<DynamicSubmissionDetailView> {
  final Map<String, String> _resolvedDisplayValues = {};
  bool _isLoadingResolvers = true;

  @override
  void initState() {
    super.initState();
    _resolveAllValues();
  }

  Future<void> _resolveAllValues() async {
    for (final field in widget.template.fields) {
      final rawVal = widget.submission.answers[field.id] ??
          widget.submission.answers[field.key] ??
          widget.submission.answers[field.effectiveKey];
      if (rawVal == null || rawVal.toString().isEmpty) continue;

      final rawStr = rawVal.toString();
      if (field.referenceTarget != null && field.referenceTarget!.isNotEmpty) {
        try {
          final display = await widget.optionResolver.resolveDisplayValue(
            referenceTarget: field.referenceTarget!,
            rawValue: rawStr,
            contextId: widget.submission.contextId,
          );
          _resolvedDisplayValues[field.id] = display;
        } catch (_) {
          _resolvedDisplayValues[field.id] = rawStr;
        }
      } else {
        // If static options exist, map label
        final match = field.options.where((o) => o.value == rawStr).firstOrNull;
        _resolvedDisplayValues[field.id] = match?.label ?? rawStr;
      }
    }

    if (mounted) {
      setState(() => _isLoadingResolvers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final sub = widget.submission;
    final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(sub.submittedAt);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (widget.headerBuilder != null)
          widget.headerBuilder!(context, sub)
        else
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(formTheme.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.template.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sub.status.name.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted: $formattedDate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (sub.submittedByUserId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'User ID: ${sub.submittedByUserId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Answers', style: formTheme.sectionHeaderStyle),
        const SizedBox(height: 8),
        ...widget.template.fields.map((field) {
          final rawVal = sub.answers[field.id] ??
              sub.answers[field.key] ??
              sub.answers[field.effectiveKey];
          final hasVal = rawVal != null && rawVal.toString().isNotEmpty;

          final displayVal = _isLoadingResolvers
              ? (rawVal?.toString() ?? '—')
              : (_resolvedDisplayValues[field.id] ?? rawVal?.toString() ?? '—');

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(formTheme.borderRadius),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasVal ? displayVal : 'Not answered',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: hasVal
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }),
        if (widget.footerBuilder != null) ...[
          const SizedBox(height: 24),
          widget.footerBuilder!(context, sub),
        ],
      ],
    );
  }
}
