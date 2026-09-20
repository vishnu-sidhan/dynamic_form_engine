import 'package:flutter/material.dart';
import '../../core/models/form_field_definition.dart';
import '../controllers/form_flow_controller.dart';
import '../../core/theme/form_theme_data.dart';

/// Pure Flutter signature canvas painter.
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;

  const SignaturePainter(this.points, {this.strokeColor = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}

/// Default renderer for capturing hand-drawn signatures.
class SignatureFieldRenderer extends StatefulWidget {
  final FormFieldDefinition field;
  final FormFlowController controller;

  const SignatureFieldRenderer({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  State<SignatureFieldRenderer> createState() => _SignatureFieldRendererState();
}

class _SignatureFieldRendererState extends State<SignatureFieldRenderer> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formTheme = FormThemeData.fromContext(context);
    final error = widget.controller.getError(widget.field.id) ??
        widget.controller.getError(widget.field.key);
    final isReadOnly = widget.field.isReadOnly || widget.controller.readOnly;

    final rawVal = widget.controller.getAnswer(widget.field.id) ??
        widget.controller.getAnswer(widget.field.key);
    final hasSignature = rawVal != null && rawVal.toString().isNotEmpty;

    return Padding(
      padding: formTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.field.label, style: formTheme.fieldLabelStyle),
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
              child: Text(widget.field.hint!, style: formTheme.fieldHintStyle),
            ),
          const SizedBox(height: 6),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(formTheme.borderRadius),
              border: Border.all(
                color: error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: isReadOnly
                ? Center(
                    child: hasSignature
                        ? Text(
                            'Signature Recorded',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            'No signature',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(formTheme.borderRadius),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final box = context.findRenderObject() as RenderBox?;
                            if (box != null) {
                              final local = details.localPosition;
                              setState(() => _points.add(local));
                            }
                          },
                          onPanEnd: (_) {
                            setState(() => _points.add(null));
                            widget.controller.updateAnswerAndRecalculate(
                              widget.field.id,
                              'signature_captured_${_points.length}_pts',
                            );
                          },
                          child: CustomPaint(
                            painter: SignaturePainter(
                              _points,
                              strokeColor: theme.colorScheme.primary,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                      if (_points.isEmpty && !hasSignature)
                        Center(
                          child: Text(
                            'Sign here with finger or mouse',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() => _points.clear());
                            widget.controller.updateAnswerAndRecalculate(
                              widget.field.id,
                              '',
                            );
                          },
                          icon: Icon(Icons.clear_rounded,
                              size: 16, color: theme.colorScheme.error),
                          label: Text(
                            'Clear',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
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
}
