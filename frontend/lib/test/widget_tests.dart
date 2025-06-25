import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:extensao_frontend/main.dart';
import 'package:extensao_frontend/pages/login_page.dart';
import 'package:extensao_frontend/pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:extensao_frontend/services/auth_service.dart';

void main() {
  testWidgets('App should render home page as initial route', (WidgetTester tester) async {
    await tester.pumpWidget(CmeiApp());
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Navigation drawer should contain all main routes', (WidgetTester tester) async {
    await tester.pumpWidget(CmeiApp());
    
    // Open the drawer
    await tester.dragFrom(const Offset(20, 200), const Offset(300, 200));
    await tester.pumpAndSettle();
    
    // Check if all main navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rotina'), findsOneWidget);
    expect(find.text('Saúde'), findsOneWidget);
    expect(find.text('Calendário'), findsOneWidget);
    expect(find.text('Avisos'), findsOneWidget);
  });

  testWidgets('Login page should have email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: LoginPage(),
        ),
      ),
    );
    
    expect(find.byType(TextFormField), findsAtLeast(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}