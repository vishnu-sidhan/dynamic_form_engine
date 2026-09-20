import 'package:flutter/material.dart';
import '../../core/models/form_template.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_submission.dart';
import '../../core/contracts/form_storage_adapter.dart';
import '../../core/contracts/form_option_resolver.dart';
import '../../core/contracts/form_submission_interceptor.dart';
import '../../core/theme/form_theme_data.dart';
import '../controllers/form_flow_controller.dart';
import '../registry/field_renderer_registry.dart';

/// Pluggable Form Filling View providing customizable UI slot builders.
class DynamicFormFillView extends StatefulWidget {
  final FormTemplate? template;
  final FormFlowController? controller;
  final FormStorageAdapter? storageAdapter;
  final FormOptionResolver? optionResolver;
  final List<FormSubmissionInterceptor> interceptors;
  final FieldRendererRegistry? registry;
  final Map<String, dynamic> initialAnswers;
  final bool readOnly;

  // Custom UI Slots
  final Widget Function(BuildContext context, FormTemplate template)? headerBuilder;
  final Widget Function(BuildContext context, FormFieldDefinition field, Widget child, bool isPrefilled)?
      fieldWrapperBuilder;
  final Widget Function(BuildContext context, FormFlowController controller, VoidCallback onSubmit)?
      submitButtonBuilder;
  final Widget Function(BuildContext context)? emptyStateBuilder;

  // Lifecycle Callbacks
  final void Function(FormSubmission submission)? onSubmitted;
  final void Function(String error)? onError;

  const DynamicFormFillView({
    super.key,
    this.template,
    this.controller,
    this.storageAdapter,
    this.optionResolver,
    this.interceptors = const [],
    this.registry,
    this.initialAnswers = const {},
    this.readOnly = false,
    this.headerBuilder,
    this.fieldWrapperBuilder,
    this.submitButtonBuilder,
    this.emptyStateBuilder,
    this.onSubmitted,
    this.onError,
  }) : assert(
          template != null || controller != null,
          'Either template or controller must be supplied to DynamicFormFillView',
        );

  @override
  State<DynamicFormFillView> createState() => _DynamicFormFillViewState();
}

class _DynamicFormFillViewState extends State<DynamicFormFillView> {
  late final FormFlowController _controller;
  late final bool _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _internalController = false;
    } else {
      _controller = FormFlowController(
        template: widget.template!,
        storageAdapter: widget.storageAdapter,
        optionResolver: widget.optionResolver ?? const DefaultFormOptionResolver(),
        interceptors: widget.interceptors,
        initialAnswers: widget.initialAnswers,
        readOnly: widget.readOnly,
      );
      _internalController = true;
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    try {
      final submission = await _controller.submit();
      if (submission != null) {
        widget.onSubmitted?.call(submission);
      } else {
        widget.onError?.call('Please correct the errors in the form.');
      }
    } catch (e) {
      widget.onError?.call(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final registry = widget.registry ?? FieldRendererRegistry.global;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final fields = _controller.fields;

        if (fields.isEmpty) {
          if (widget.emptyStateBuilder != null) {
            return widget.emptyStateBuilder!(context);
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'This form has no fields.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Slot: Header
            if (widget.headerBuilder != null)
              widget.headerBuilder!(context, _controller.template)
            else
              _buildDefaultHeader(context, _controller.template),

            const SizedBox(height: 16),

            // Dynamic Form Fields
            ...fields.map((field) {
              if (!_controller.isFieldVisible(field)) {
                return const SizedBox.shrink();
              }

              final fieldWidget = registry.buildWidget(
                context: context,
                field: field,
                controller: _controller,
              );

              final isPrefilled = _controller.prefilledKeys.contains(field.id) ||
                  _controller.prefilledKeys.contains(field.key);

              if (widget.fieldWrapperBuilder != null) {
                return widget.fieldWrapperBuilder!(
                  context,
                  field,
                  fieldWidget,
                  isPrefilled,
                );
              }

              if (isPrefilled) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: formTheme.prefilledHighlightColor,
                    borderRadius: BorderRadius.circular(formTheme.borderRadius),
                  ),
                  child: fieldWidget,
                );
              }

              return fieldWidget;
            }),

            const SizedBox(height: 24),

            // Slot: Submit Button
            if (!_controller.readOnly)
              if (widget.submitButtonBuilder != null)
                widget.submitButtonBuilder!(context, _controller, _handleSubmit)
              else
                _buildDefaultSubmitButton(context, formTheme),
          ],
        );
      },
    );
  }

  Widget _buildDefaultHeader(BuildContext context, FormTemplate template) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          template.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (template.description != null && template.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            template.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultSubmitButton(BuildContext context, FormThemeData formTheme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _controller.isSubmitting ? null : _handleSubmit,
        style: formTheme.primaryButtonStyle,
        child: _controller.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit Form',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}
