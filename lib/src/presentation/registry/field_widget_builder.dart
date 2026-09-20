import 'package:flutter/widgets.dart';
import '../../core/models/form_field_definition.dart';
import '../controllers/form_flow_controller.dart';

/// Builder signature for rendering a dynamic form field widget.
typedef FieldWidgetBuilder = Widget Function(
  BuildContext context,
  FormFieldDefinition field,
  FormFlowController controller,
);
