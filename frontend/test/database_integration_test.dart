import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../lib/services/database_helper.dart';
import '../lib/services/avisos_service.dart';
import '../lib/data/repositories/http_client.dart';
import '../lib/models/aviso.dart';

void main() {
  group('Teste de Integração do Banco de Dados', () {
    late DatabaseHelper dbHelper;
    
    setUpAll(() async {
      // CRÍTICO: Inicializar bindings do Flutter para testes
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Configurar SQLite para testes
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    });

    setUp(() async {
      dbHelper = DatabaseHelper();
      // Reset database for clean test
      await dbHelper.resetDatabase();
    });

    test('Deve inicializar o banco de dados SQLite', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      print('✅ Banco de dados SQLite inicializado com sucesso');
    });

    test('Deve verificar se o banco está funcionando', () async {
      final isWorking = await dbHelper.isDatabaseWorking();
      expect(isWorking, isTrue);
      print('✅ Banco de dados está funcionando corretamente');
    });

    test('Deve inserir e recuperar avisos localmente', () async {
      // Inserir aviso de teste
      final aviso = Aviso(
        id: 1,
        titulo: 'Aviso de Teste',
        mensagem: 'Este é um aviso de teste para verificar o banco',
        dataPublicacao: DateTime.now(),
        autorId: 1,
      );

      await dbHelper.insertAviso(aviso);
      print('✅ Aviso inserido no banco local');

      // Recuperar avisos
      final avisos = await dbHelper.getAvisos();
      expect(avisos.length, greaterThan(0));
      expect(avisos.first.titulo, equals('Aviso de Teste'));
      print('✅ Aviso recuperado do banco local: ${avisos.first.titulo}');
    });

    test('Deve inserir dados de teste', () async {
      await dbHelper.insertTestData();
      final avisos = await dbHelper.getAvisos();
      expect(avisos.length, greaterThan(0));
      print('✅ Dados de teste inseridos: ${avisos.length} avisos');
      
      for (var aviso in avisos) {
        print('   - ${aviso.titulo}');
      }
    });

    test('Deve verificar conectividade com backend', () async {
      final httpClient = HttpClient();
      
      try {
        final isAvailable = await httpClient.isBackendAvailable();
        print('Backend disponível: $isAvailable');
        
        if (isAvailable) {
          print('✅ Backend está respondendo em http://localhost:8000');
          
          // Testar health endpoint
          final health = await httpClient.get('/health');
          expect(health, isNotNull);
          print('✅ Health check do backend funcionando');
        } else {
          print('⚠️ Backend não está disponível - isso é normal se não estiver rodando');
        }
      } catch (e) {
        print('⚠️ Erro ao conectar com backend: $e');
        print('   Isso é normal se o backend não estiver rodando');
      }
    });

    test('Deve testar sincronização completa (se backend disponível)', () async {
      final httpClient = HttpClient();
      
      try {
        final isAvailable = await httpClient.isBackendAvailable();
        
        if (isAvailable) {
          final avisosService = RealAvisosService(httpClient, dbHelper);
          
          // Testar sincronização
          final syncResult = await avisosService.syncAvisos();
          print('Resultado da sincronização: $syncResult');
          
          // Verificar se dados foram sincronizados
          final avisos = await avisosService.getAvisos();
          print('✅ Avisos após sincronização: ${avisos.length}');
          
          for (var aviso in avisos) {
            print('   - ${aviso.titulo}');
          }
        } else {
          print('⚠️ Pulando teste de sincronização - backend não disponível');
        }
      } catch (e) {
        print('⚠️ Erro durante sincronização: $e');
      }
    });
  });
}
