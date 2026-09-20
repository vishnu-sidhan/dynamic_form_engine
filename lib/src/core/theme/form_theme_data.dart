import 'package:flutter/material.dart';

/// Styling and decoration configuration for dynamic form widgets.
/// Inherits dynamically from Flutter's [ThemeData] and [ColorScheme] by default.
class FormThemeData {
  final EdgeInsetsGeometry fieldPadding;
  final EdgeInsetsGeometry contentPadding;
  final double fieldSpacing;
  final double borderRadius;
  final InputDecoration? inputDecoration;
  final TextStyle? sectionHeaderStyle;
  final TextStyle? fieldLabelStyle;
  final TextStyle? fieldHintStyle;
  final TextStyle? calculatedBadgeStyle;
  final Color? prefilledHighlightColor;
  final Color? calculatedFieldBackgroundColor;
  final ButtonStyle? primaryButtonStyle;
  final ButtonStyle? secondaryButtonStyle;

  const FormThemeData({
    this.fieldPadding = const EdgeInsets.symmetric(vertical: 8.0),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
    this.fieldSpacing = 16.0,
    this.borderRadius = 12.0,
    this.inputDecoration,
    this.sectionHeaderStyle,
    this.fieldLabelStyle,
    this.fieldHintStyle,
    this.calculatedBadgeStyle,
    this.prefilledHighlightColor,
    this.calculatedFieldBackgroundColor,
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
  });

  /// Derives effective styling dynamically from ambient [BuildContext] and [ThemeData].
  factory FormThemeData.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FormThemeData(
      fieldPadding: const EdgeInsets.symmetric(vertical: 8.0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      fieldSpacing: 16.0,
      borderRadius: 12.0,
      sectionHeaderStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      fieldLabelStyle: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      fieldHintStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      calculatedBadgeStyle: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
      prefilledHighlightColor: colorScheme.secondaryContainer.withValues(alpha: 0.35),
      calculatedFieldBackgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      inputDecoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      ),
    );
  }
}
