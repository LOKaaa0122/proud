import 'package:be_proud/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const BeProudApp());
    expect(find.text('Be Proud'), findsOneWidget);
  });
}
