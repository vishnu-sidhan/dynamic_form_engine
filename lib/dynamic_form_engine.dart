library dynamic_form_engine;

// Core Contracts (SPI)
export 'src/core/contracts/form_storage_adapter.dart';
export 'src/core/contracts/form_sync_delegate.dart';
export 'src/core/contracts/form_option_resolver.dart';
export 'src/core/contracts/form_submission_interceptor.dart';

// Core Models
export 'src/core/models/form_enums.dart';
export 'src/core/models/form_field_definition.dart';
export 'src/core/models/form_template.dart';
export 'src/core/models/form_submission.dart';
export 'src/core/models/outbox_mutation.dart';

// Theme
export 'src/core/theme/form_theme_data.dart';

// Logic Engines & Services
export 'src/services/formula_evaluator.dart';
export 'src/services/field_validator.dart';
export 'src/services/template_sync_service.dart';

// Storage Implementations
export 'src/storage/default_sembast_adapter.dart';

// Presentation Layer
export 'src/presentation/controllers/form_flow_controller.dart';
export 'src/presentation/registry/field_widget_builder.dart';
export 'src/presentation/registry/field_renderer_registry.dart';

// Default Renderers
export 'src/presentation/renderers/text_field_renderer.dart';
export 'src/presentation/renderers/selection_field_renderer.dart';
export 'src/presentation/renderers/date_time_field_renderer.dart';
export 'src/presentation/renderers/media_field_renderer.dart';
export 'src/presentation/renderers/signature_field_renderer.dart';
export 'src/presentation/renderers/location_field_renderer.dart';
export 'src/presentation/renderers/calculated_field_renderer.dart';
export 'src/presentation/renderers/group_repeater_field_renderer.dart';

// Pluggable Views
export 'src/presentation/views/dynamic_form_fill_view.dart';
export 'src/presentation/views/dynamic_form_creator_view.dart';
export 'src/presentation/views/dynamic_submission_detail_view.dart';
