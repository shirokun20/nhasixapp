import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native_example/main.dart';

void main() {
  testWidgets('Demo app shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('AI Translation Pipeline'), findsOneWidget);
    expect(find.text('Load Test Image'), findsOneWidget);
  });
}
