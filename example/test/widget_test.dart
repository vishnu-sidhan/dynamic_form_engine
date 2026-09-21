import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_form_engine_example/main.dart';
import 'package:dynamic_form_engine/dynamic_form_engine.dart';

void main() {
  testWidgets('DynamicFormEngineExampleApp smoke test', (WidgetTester tester) async {
    final storage = DefaultSembastStorageAdapter();
    await storage.initialize();
    await tester.pumpWidget(DynamicFormEngineExampleApp(storageAdapter: storage));
    await tester.pumpAndSettle();

    expect(find.text('Dynamic Form Engine'), findsOneWidget);
  });
}
