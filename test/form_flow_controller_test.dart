import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

class MockInterceptor implements FormSubmissionInterceptor {
  bool beforeCalled = false;
  bool afterCalled = false;
  bool reversedCalled = false;

  @override
  Future<void> onBeforeSubmit(FormSubmission submission) async {
    beforeCalled = true;
  }

  @override
  Future<void> onAfterSubmit(FormSubmission submission) async {
    afterCalled = true;
  }

  @override
  Future<void> onSubmissionReversed(String submissionId) async {
    reversedCalled = true;
  }
}

void main() {
  group('FormFlowController', () {
    late DefaultSembastStorageAdapter storage;
    late FormTemplate template;
    late MockInterceptor interceptor;

    setUp(() async {
      storage = DefaultSembastStorageAdapter();
      await storage.initialize();

      template = FormTemplate(
        id: 'tmpl-1',
        name: 'Test Invoice Form',
        createdAt: DateTime.now(),
        fields: const [
          FormFieldDefinition(
            id: 'qty',
            formId: 'tmpl-1',
            key: 'quantity',
            label: 'Quantity',
            fieldType: FormFieldType.number,
            isRequired: true,
          ),
          FormFieldDefinition(
            id: 'rate',
            formId: 'tmpl-1',
            key: 'unit_rate',
            label: 'Unit Rate',
            fieldType: FormFieldType.decimal,
            isRequired: true,
          ),
          FormFieldDefinition(
            id: 'total',
            formId: 'tmpl-1',
            key: 'total_amount',
            label: 'Total Amount',
            fieldType: FormFieldType.calculated,
            calculationFormula: '[quantity] * [unit_rate]',
          ),
        ],
      );

      interceptor = MockInterceptor();
    });

    test('updates answer and triggers live recalculations', () {
      final controller = FormFlowController(
        template: template,
        storageAdapter: storage,
        interceptors: [interceptor],
      );

      expect(controller.getAnswer('total'), isNull);

      controller.updateAnswerAndRecalculate('quantity', '5');
      controller.updateAnswerAndRecalculate('unit_rate', '12.5');

      expect(controller.getAnswer('total'), '62.50');
      expect(controller.isDirty, isTrue);
    });

    test('fails validation when required fields are missing', () async {
      final controller = FormFlowController(
        template: template,
        storageAdapter: storage,
        interceptors: [interceptor],
      );

      final isValid = controller.validate();
      expect(isValid, isFalse);
      expect(controller.getError('quantity'), isNotNull);

      final sub = await controller.submit();
      expect(sub, isNull);
      expect(interceptor.beforeCalled, isFalse);
    });

    test('successfully validates, invokes interceptors, and saves submission',
        () async {
      final controller = FormFlowController(
        template: template,
        storageAdapter: storage,
        interceptors: [interceptor],
      );

      controller.updateAnswerAndRecalculate('quantity', '10');
      controller.updateAnswerAndRecalculate('unit_rate', '5.0');

      final submission = await controller.submit(
        submittedByUserId: 'user-42',
        contextId: 'tenant-alpha',
      );

      expect(submission, isNotNull);
      expect(submission!.answers['quantity'], '10');
      expect(submission.answers['total'], '50.00');
      expect(interceptor.beforeCalled, isTrue);
      expect(interceptor.afterCalled, isTrue);

      // Verify saved in storage adapter
      final fetched = await storage.getSubmissionById(submission.id);
      expect(fetched, isNotNull);
      expect(fetched!.formId, 'tmpl-1');
      expect(fetched.answers['total'], '50.00');
    });
  });
}
