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
  final void Function(Map<String, dynamic> data)? onSubmit;
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
    this.onSubmit,
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
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _fieldKeys = {};

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
    _scrollController.dispose();
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final field in _controller.fields) {
        if (!_controller.isFieldVisible(field)) continue;
        final hasError = _controller.getError(field.id) != null ||
            _controller.getError(field.key) != null;
        if (hasError) {
          final key = _fieldKeys[field.id];
          final currentContext = key?.currentContext;
          if (currentContext != null) {
            Scrollable.ensureVisible(
              currentContext,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
            break;
          }
        }
      }
    });
  }

  Future<void> _handleSubmit() async {
    try {
      final submission = await _controller.submit();
      if (submission != null) {
        widget.onSubmitted?.call(submission);
        widget.onSubmit?.call(submission.answers);
      } else {
        _scrollToFirstError();
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
          controller: _scrollController,
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

              final key = _fieldKeys.putIfAbsent(field.id, () => GlobalKey());

              Widget wrapped;
              if (widget.fieldWrapperBuilder != null) {
                wrapped = widget.fieldWrapperBuilder!(
                  context,
                  field,
                  fieldWidget,
                  isPrefilled,
                );
              } else if (isPrefilled) {
                wrapped = Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: formTheme.prefilledHighlightColor,
                    borderRadius: BorderRadius.circular(formTheme.borderRadius),
                  ),
                  child: fieldWidget,
                );
              } else {
                wrapped = fieldWidget;
              }

              return KeyedSubtree(
                key: key,
                child: wrapped,
              );
            }),

            const SizedBox(height: 16),

            // Validation Error Summary Banner
            if (_controller.errors.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(formTheme.borderRadius),
                  border: Border.all(color: theme.colorScheme.error),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Please correct the following errors:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._controller.fields
                        .where((f) =>
                            _controller.isFieldVisible(f) &&
                            (_controller.getError(f.id) != null ||
                                _controller.getError(f.key) != null))
                        .map((f) {
                      final err = _controller.getError(f.id) ??
                          _controller.getError(f.key)!;
                      return InkWell(
                        onTap: () {
                          final key = _fieldKeys[f.id];
                          if (key?.currentContext != null) {
                            Scrollable.ensureVisible(
                              key!.currentContext!,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: 0.1,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${f.label}: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onErrorContainer,
                                        ),
                                      ),
                                      TextSpan(
                                        text: err,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 8),

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
        if (template.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            template.description,
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
