import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_enums.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Default renderer for single-line text, multi-line textarea, number, decimal, currency, email, and phone fields.
class TextFieldRenderer extends StatefulWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;

  const TextFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  State<TextFieldRenderer> createState() => _TextFieldRendererState();
}

class _TextFieldRendererState extends State<TextFieldRenderer> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.getAnswer(widget.field.id) ??
        widget.controller.getAnswer(widget.field.key) ??
        '';
    _textController = TextEditingController(text: initial.toString());
  }

  @override
  void didUpdateWidget(covariant TextFieldRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.controller.getAnswer(widget.field.id) ??
        widget.controller.getAnswer(widget.field.key) ??
        '';
    if (_textController.text != current.toString()) {
      _textController.text = current.toString();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final error = widget.controller.getError(widget.field.id) ??
        widget.controller.getError(widget.field.key);
    final isReadOnly = widget.field.isReadOnly || widget.controller.readOnly;

    TextInputType keyboardType = TextInputType.text;
    List<TextInputFormatter> formatters = [];
    int maxLines = 1;

    switch (widget.field.fieldType) {
      case FormFieldType.textarea:
        maxLines = 4;
        keyboardType = TextInputType.multiline;
        break;
      case FormFieldType.number:
        keyboardType = const TextInputType.numberWithOptions(signed: true);
        formatters = [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))];
        break;
      case FormFieldType.decimal:
      case FormFieldType.currency:
        keyboardType = const TextInputType.numberWithOptions(decimal: true, signed: true);
        formatters = [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))];
        break;
      case FormFieldType.email:
        keyboardType = TextInputType.emailAddress;
        break;
      case FormFieldType.phone:
        keyboardType = TextInputType.phone;
        break;
      default:
        keyboardType = TextInputType.text;
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
          TextFormField(
            controller: _textController,
            readOnly: isReadOnly,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            maxLines: maxLines,
            onChanged: (val) {
              widget.controller.updateAnswerAndRecalculate(widget.field.id, val);
            },
            decoration: (formTheme.inputDecoration ?? const InputDecoration())
                .copyWith(
              hintText: widget.field.hint,
              errorText: error,
              prefixText: widget.field.fieldType == FormFieldType.currency ? '\$ ' : null,
              suffixIcon: isReadOnly
                  ? Icon(Icons.lock_outline_rounded,
                      size: 18, color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
