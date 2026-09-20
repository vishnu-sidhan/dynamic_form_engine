import '../models/form_submission.dart';

/// Extension lifecycle hooks to intercept form submissions before/after writing to storage.
/// Used for triggering audit logs, external webhooks, notifications, or database transactions.
abstract class FormSubmissionInterceptor {
  /// Invoked immediately before persisting the submission.
  /// Throwing an exception here safely aborts the submission transaction.
  Future<void> onBeforeSubmit(FormSubmission submission);

  /// Invoked immediately after successfully persisting the submission.
  Future<void> onAfterSubmit(FormSubmission submission);

  /// Invoked when a prior submission has been cancelled, deleted, or reversed.
  Future<void> onSubmissionReversed(String submissionId);
}

/// Composite interceptor to chain multiple interceptors sequentially.
class CompositeFormSubmissionInterceptor implements FormSubmissionInterceptor {
  final List<FormSubmissionInterceptor> interceptors;

  const CompositeFormSubmissionInterceptor(this.interceptors);

  @override
  Future<void> onBeforeSubmit(FormSubmission submission) async {
    for (final interceptor in interceptors) {
      await interceptor.onBeforeSubmit(submission);
    }
  }

  @override
  Future<void> onAfterSubmit(FormSubmission submission) async {
    for (final interceptor in interceptors) {
      await interceptor.onAfterSubmit(submission);
    }
  }

  @override
  Future<void> onSubmissionReversed(String submissionId) async {
    for (final interceptor in interceptors) {
      await interceptor.onSubmissionReversed(submissionId);
    }
  }
}
