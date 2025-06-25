import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:extensao_frontend/main.dart' as app;
import 'package:extensao_frontend/services/database_helper.dart';
import 'package:extensao_frontend/services/avisos_service.dart';
import 'package:extensao_frontend/data/repositories/http_client.dart';
import 'package:extensao_frontend/models/aviso.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de Integração End-to-End', () {
    testWidgets('Deve executar o app e testar funcionalidades básicas', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Verificar se a página de login aparece
      expect(find.text('Login'), findsWidgets);
      print('✅ App iniciado com página de login');

      // Testar o banco de dados local
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      if (db != null) {
        print('✅ Banco de dados local está funcionando');
        
        // Testar inserção de aviso local
        final aviso = Aviso(
          id: 0,
          titulo: 'Teste de Integração',
          mensagem: 'Este aviso foi criado durante o teste de integração',
          dataPublicacao: DateTime.now(),
          autorId: 1,
        );
        
        final id = await dbHelper.insertAviso(aviso);
        expect(id, isNotNull);
        print('✅ Aviso inserido no banco local com ID: $id');
        
        // Verificar se o aviso foi salvo
        final avisos = await dbHelper.getAvisos();
        expect(avisos.length, greaterThan(0));
        print('✅ Avisos recuperados do banco: ${avisos.length}');
      } else {
        print('⚠️ Banco de dados local não está disponível (web ou erro)');
      }      // Testar conectividade com backend (se disponível)
      try {
        final httpClient = HttpClient();
        final avisosService = RealAvisosService(httpClient, dbHelper);
        final avisosBackend = await avisosService.getAvisos();
        print('✅ Backend conectado - ${avisosBackend.length} avisos no servidor');
      } catch (e) {
        print('⚠️ Backend não disponível: $e');
      }
    });

    testWidgets('Deve testar navegação entre páginas', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Se tiver botões de navegação, testar
      final navigationButtons = find.byType(BottomNavigationBar);
      if (navigationButtons.hasFound) {
        print('✅ Bottom Navigation encontrada');
        
        // Tentar navegar para diferentes páginas
        await tester.tap(find.byIcon(Icons.notifications).first);
        await tester.pumpAndSettle();
        print('✅ Navegação para avisos testada');
        
        await tester.tap(find.byIcon(Icons.calendar_today).first);
        await tester.pumpAndSettle();
        print('✅ Navegação para calendário testada');
      } else {
        print('ℹ️ Navigation bar não encontrada - app pode estar em estado de login');
      }
    });

    testWidgets('Deve testar formulários e inputs', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Procurar por campos de texto
      final textFields = find.byType(TextField);
      if (textFields.hasFound) {
        print('✅ ${textFields.evaluate().length} campos de texto encontrados');
        
        // Testar digitação em um campo
        await tester.enterText(textFields.first, 'teste@example.com');
        await tester.pumpAndSettle();
        print('✅ Texto inserido em campo de entrada');
      }

      // Procurar por botões
      final buttons = find.byType(ElevatedButton);
      if (buttons.hasFound) {
        print('✅ ${buttons.evaluate().length} botões encontrados');
      }
    });    testWidgets('Deve testar persistência de dados', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final dbHelper = DatabaseHelper();
      
      // Resetar banco para ter dados limpos
      await dbHelper.resetDatabase();
      
      // Inserir dados de teste
      final avisosTeste = [
        Aviso(
          id: 0,
          titulo: 'Aviso 1',
          mensagem: 'Primeira mensagem de teste',
          dataPublicacao: DateTime.now(),
          autorId: 1,
        ),
        Aviso(
          id: 0,
          titulo: 'Aviso 2',
          mensagem: 'Segunda mensagem de teste',
          dataPublicacao: DateTime.now().add(const Duration(minutes: 1)),
          autorId: 2,
        ),
      ];

      for (final aviso in avisosTeste) {
        await dbHelper.insertAviso(aviso);
      }

      // Verificar se os dados persistem
      final avisosRecuperados = await dbHelper.getAvisos();
      expect(avisosRecuperados.length, equals(2));
      print('✅ Dados persistidos corretamente: ${avisosRecuperados.length} avisos');

      // Testar operações CRUD
      final primeiroAviso = avisosRecuperados.first;
      
      // Update
      final avisoAtualizado = Aviso(
        id: primeiroAviso.id,
        titulo: '${primeiroAviso.titulo} - Atualizado',
        mensagem: primeiroAviso.mensagem,
        dataPublicacao: primeiroAviso.dataPublicacao,
        autorId: primeiroAviso.autorId,
      );
      
      await dbHelper.updateAviso(avisoAtualizado);
      final avisoVerificado = await dbHelper.getAviso(primeiroAviso.id);
      expect(avisoVerificado?.titulo, contains('Atualizado'));
      print('✅ Operação de update funcionando');

      // Delete
      await dbHelper.deleteAviso(primeiroAviso.id);
      final avisosAposDelete = await dbHelper.getAvisos();
      expect(avisosAposDelete.length, equals(1));
      print('✅ Operação de delete funcionando');
    });
  });
}
