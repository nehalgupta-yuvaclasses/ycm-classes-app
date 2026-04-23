import 'package:flutter_test/flutter_test.dart';
import 'package:yuva_classes/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const YuvaClassesApp());
    await tester.pumpAndSettle();
    // App should render without crashing
    expect(find.byType(YuvaClassesApp), findsOneWidget);
  });
}
