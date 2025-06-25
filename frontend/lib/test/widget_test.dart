import 'package:flutter_test/flutter_test.dart';
import 'package:extensao_frontend/main.dart';

void main() {
  testWidgets('Login button navigates to home', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(CmeiApp());

    // Verify the login button is present
    expect(find.text('Simular Login'), findsOneWidget);

    // Tap the login button
    await tester.tap(find.text('Simular Login'));
    await tester.pumpAndSettle();

    // Verify navigation to the home page
    expect(find.text('CMEI Home'), findsOneWidget);
  });
}