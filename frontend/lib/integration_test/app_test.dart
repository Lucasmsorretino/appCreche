import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:extensao_frontend/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full app navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(CmeiApp());
    
    // Verify we start on home page
    expect(find.text('CMEI Home'), findsOneWidget);
    
    // Open drawer and navigate to Routine
    await tester.dragFrom(const Offset(20, 200), const Offset(300, 200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rotina'));
    await tester.pumpAndSettle();
    
    // Verify we're on Routine page
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Rotina'), findsOneWidget);
    
    // Navigate to Health page
    await tester.dragFrom(const Offset(20, 200), const Offset(300, 200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saúde'));
    await tester.pumpAndSettle();
    
    // Verify we're on Health page
    expect(find.text('Saúde'), findsOneWidget);
  });
}