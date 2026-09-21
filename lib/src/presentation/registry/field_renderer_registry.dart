import 'package:flutter/widgets.dart';
import '../../core/models/form_field_definition.dart';
import '../../core/models/form_enums.dart';
import '../controllers/form_flow_controller.dart';
import 'field_widget_builder.dart';
import '../renderers/text_field_renderer.dart';
import '../renderers/selection_field_renderer.dart';
import '../renderers/date_time_field_renderer.dart';
import '../renderers/media_field_renderer.dart';
import '../renderers/signature_field_renderer.dart';
import '../renderers/location_field_renderer.dart';
import '../renderers/calculated_field_renderer.dart';
import '../renderers/group_repeater_field_renderer.dart';

/// Strategy registry for rendering dynamic form fields.
/// Maintains global and instance mappings from [FormFieldType] to custom or default [FieldWidgetBuilder] implementations.
class FieldRendererRegistry {
  final Map<FormFieldType, FieldWidgetBuilder> _builders = {};

  static final FieldRendererRegistry global = FieldRendererRegistry._default();

  FieldRendererRegistry() {
    _registerDefaults();
  }

  FieldRendererRegistry._default() {
    _registerDefaults();
  }

  void _registerDefaults() {
    Widget textBuilder(
        BuildContext ctx, FormFieldDefinition f, FormFlowController c) {
      return TextFieldRenderer(field: f, controller: c);
    }

    _builders[FormFieldType.text] = textBuilder;
    _builders[FormFieldType.textarea] = textBuilder;
    _builders[FormFieldType.number] = textBuilder;
    _builders[FormFieldType.decimal] = textBuilder;
    _builders[FormFieldType.currency] = textBuilder;
    _builders[FormFieldType.email] = textBuilder;
    _builders[FormFieldType.phone] = textBuilder;

    Widget selectionBuilder(
        BuildContext ctx, FormFieldDefinition f, FormFlowController c) {
      return SelectionFieldRenderer(field: f, controller: c);
    }

    _builders[FormFieldType.dropdown] = selectionBuilder;
    _builders[FormFieldType.radio] = selectionBuilder;
    _builders[FormFieldType.checkbox] = selectionBuilder;
    _builders[FormFieldType.multiSelect] = selectionBuilder;
    _builders[FormFieldType.toggle] = selectionBuilder;

    Widget dateTimeBuilder(
        BuildContext ctx, FormFieldDefinition f, FormFlowController c) {
      return DateTimeFieldRenderer(field: f, controller: c);
    }

    _builders[FormFieldType.date] = dateTimeBuilder;
    _builders[FormFieldType.time] = dateTimeBuilder;
    _builders[FormFieldType.dateTime] = dateTimeBuilder;
    _builders[FormFieldType.dateRange] = dateTimeBuilder;

    Widget mediaBuilder(
        BuildContext ctx, FormFieldDefinition f, FormFlowController c) {
      return MediaFieldRenderer(field: f, controller: c);
    }

    _builders[FormFieldType.image] = mediaBuilder;
    _builders[FormFieldType.video] = mediaBuilder;
    _builders[FormFieldType.document] = mediaBuilder;
    _builders[FormFieldType.media] = mediaBuilder;

    _builders[FormFieldType.signature] = (ctx, f, c) =>
        SignatureFieldRenderer(field: f, controller: c);

    Widget locationBuilder(
        BuildContext ctx, FormFieldDefinition f, FormFlowController c) {
      return LocationFieldRenderer(field: f, controller: c);
    }

    _builders[FormFieldType.gps] = locationBuilder;
    _builders[FormFieldType.gpsLocation] = locationBuilder;
    _builders[FormFieldType.location] = locationBuilder;

    _builders[FormFieldType.calculated] = (ctx, f, c) =>
        CalculatedFieldRenderer(field: f, controller: c);

    Widget groupBuilder(
        BuildContext ctx, FormFieldDefinition f, FormFlowController c) {
      return GroupRepeaterFieldRenderer(field: f, controller: c);
    }

    _builders[FormFieldType.dynamicFieldGroup] = groupBuilder;
    _builders[FormFieldType.groupRepeater] = groupBuilder;
  }

  /// Registers or overrides a renderer builder for a given [FormFieldType].
  void register(FormFieldType type, FieldWidgetBuilder builder) {
    _builders[type] = builder;
  }

  /// Retrieves builder for a given [FormFieldType], falling back to text renderer if unmapped.
  FieldWidgetBuilder getBuilder(FormFieldType type) {
    return _builders[type] ??
        _builders[FormFieldType.text] ??
        ((ctx, f, c) => TextFieldRenderer(field: f, controller: c));
  }

  /// Renders the field widget using the registered builder.
  Widget buildWidget({
    required BuildContext context,
    required FormFieldDefinition field,
    required FormFlowController controller,
  }) {
    final builder = getBuilder(field.fieldType);
    return builder(context, field, controller);
  }
}
