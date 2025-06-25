import 'package:flutter_test/flutter_test.dart';
import '../lib/services/database_helper_test.dart';
import '../lib/models/aviso.dart';

void main() {
  group('Database Integration Tests', () {
    late DatabaseHelperTest dbHelper;

    setUpAll(() async {
      // Inicializar o binding do Flutter para testes
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Inicializar o database helper para testes
      await DatabaseHelperTest.initializeForTest();
    });

    setUp(() async {
      // Criar uma nova instância limpa para cada teste
      DatabaseHelperTest.reset();
      dbHelper = DatabaseHelperTest();
      
      // Garantir que o banco está inicializado
      await dbHelper.database;
      
      // Limpar dados de testes anteriores
      await dbHelper.clearDatabase();
    });

    tearDown(() async {
      // Limpar após cada teste
      await dbHelper.clearDatabase();
      await dbHelper.close();
    });

    test('Deve criar e inicializar o banco de dados em memória', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      print('✅ Banco de dados em memória inicializado com sucesso');
    });

    test('Deve inserir um aviso no banco local', () async {
      final aviso = Aviso(
        id: 0, // O ID será gerado automaticamente
        titulo: 'Teste de Aviso',
        mensagem: 'Esta é uma mensagem de teste para verificar a inserção no banco local.',
        dataPublicacao: DateTime.now(),
        autorId: 1,
      );

      final id = await dbHelper.insertAviso(aviso);
      expect(id, isNotNull);
      expect(id! > 0, isTrue);
      print('✅ Aviso inserido com ID: $id');
    });

    test('Deve buscar avisos do banco local', () async {
      // Inserir alguns avisos de teste
      final aviso1 = Aviso(
        id: 0,
        titulo: 'Primeiro Aviso',
        mensagem: 'Conteúdo do primeiro aviso',
        dataPublicacao: DateTime.now().subtract(const Duration(hours: 1)),
        autorId: 1,
      );

      final aviso2 = Aviso(
        id: 0,
        titulo: 'Segundo Aviso',
        mensagem: 'Conteúdo do segundo aviso',
        dataPublicacao: DateTime.now(),
        autorId: 2,
      );

      await dbHelper.insertAviso(aviso1);
      await dbHelper.insertAviso(aviso2);

      // Buscar todos os avisos
      final avisos = await dbHelper.getAvisos();
      expect(avisos.length, equals(2));
      
      // Verificar se estão ordenados por data (mais recente primeiro)
      expect(avisos.first.titulo, equals('Segundo Aviso'));
      expect(avisos.last.titulo, equals('Primeiro Aviso'));
      
      print('✅ ${avisos.length} avisos recuperados do banco local');
      for (final aviso in avisos) {
        print('   - ${aviso.titulo}: ${aviso.mensagem}');
      }
    });

    test('Deve buscar aviso por ID', () async {
      final aviso = Aviso(
        id: 0,
        titulo: 'Aviso Específico',
        mensagem: 'Este aviso será buscado por ID',
        dataPublicacao: DateTime.now(),
        autorId: 1,
      );

      final id = await dbHelper.insertAviso(aviso);
      expect(id, isNotNull);

      final avisoEncontrado = await dbHelper.getAvisoById(id!);
      expect(avisoEncontrado, isNotNull);
      expect(avisoEncontrado!.titulo, equals('Aviso Específico'));
      expect(avisoEncontrado.mensagem, equals('Este aviso será buscado por ID'));
      
      print('✅ Aviso encontrado por ID $id: ${avisoEncontrado.titulo}');
    });

    test('Deve atualizar um aviso', () async {
      final aviso = Aviso(
        id: 0,
        titulo: 'Aviso Original',
        mensagem: 'Conteúdo original',
        dataPublicacao: DateTime.now(),
        autorId: 1,
      );

      final id = await dbHelper.insertAviso(aviso);
      expect(id, isNotNull);

      final avisoAtualizado = Aviso(
        id: id!,
        titulo: 'Aviso Atualizado',
        mensagem: 'Conteúdo atualizado',
        dataPublicacao: DateTime.now(),
        autorId: 1,
      );

      final sucesso = await dbHelper.updateAviso(avisoAtualizado);
      expect(sucesso, isTrue);

      final avisoVerificado = await dbHelper.getAvisoById(id);
      expect(avisoVerificado!.titulo, equals('Aviso Atualizado'));
      expect(avisoVerificado.mensagem, equals('Conteúdo atualizado'));
      
      print('✅ Aviso atualizado com sucesso');
    });

    test('Deve deletar um aviso', () async {
      final aviso = Aviso(
        id: 0,
        titulo: 'Aviso para Deletar',
        mensagem: 'Este aviso será deletado',
        dataPublicacao: DateTime.now(),
        autorId: 1,
      );

      final id = await dbHelper.insertAviso(aviso);
      expect(id, isNotNull);

      final sucesso = await dbHelper.deleteAviso(id!);
      expect(sucesso, isTrue);

      final avisoVerificado = await dbHelper.getAvisoById(id);
      expect(avisoVerificado, isNull);
      
      print('✅ Aviso deletado com sucesso');
    });

    test('Deve gerenciar múltiplas operações', () async {
      print('🔄 Testando múltiplas operações no banco...');
      
      // Inserir vários avisos
      final avisos = <Aviso>[];
      for (int i = 1; i <= 5; i++) {
        final aviso = Aviso(
          id: 0,
          titulo: 'Aviso $i',
          mensagem: 'Conteúdo do aviso número $i',
          dataPublicacao: DateTime.now().subtract(Duration(minutes: i)),
          autorId: i,
        );
        avisos.add(aviso);
        await dbHelper.insertAviso(aviso);
      }

      // Verificar se todos foram inseridos
      final todosAvisos = await dbHelper.getAvisos();
      expect(todosAvisos.length, equals(5));
      print('✅ ${todosAvisos.length} avisos inseridos');

      // Atualizar alguns avisos
      for (int i = 0; i < 2; i++) {
        final avisoAtualizado = Aviso(
          id: todosAvisos[i].id,
          titulo: '${todosAvisos[i].titulo} - Atualizado',
          mensagem: '${todosAvisos[i].mensagem} - Modificado',
          dataPublicacao: todosAvisos[i].dataPublicacao,
          autorId: todosAvisos[i].autorId,
        );
        await dbHelper.updateAviso(avisoAtualizado);
      }
      print('✅ 2 avisos atualizados');

      // Deletar alguns avisos
      for (int i = 2; i < 4; i++) {
        await dbHelper.deleteAviso(todosAvisos[i].id);
      }
      print('✅ 2 avisos deletados');

      // Verificar estado final
      final avisosFinais = await dbHelper.getAvisos();
      expect(avisosFinais.length, equals(3));
      
      // Verificar se os avisos atualizados têm o texto correto
      final avisosAtualizados = avisosFinais.where((a) => a.titulo.contains('Atualizado')).toList();
      expect(avisosAtualizados.length, equals(2));
      
      print('✅ Estado final: ${avisosFinais.length} avisos restantes');
      print('✅ Teste de múltiplas operações concluído com sucesso!');
    });

    test('Deve lidar com casos extremos', () async {
      print('🔄 Testando casos extremos...');
      
      // Tentar buscar aviso inexistente
      final avisoInexistente = await dbHelper.getAvisoById(999);
      expect(avisoInexistente, isNull);
      print('✅ Busca por ID inexistente retorna null');

      // Tentar deletar aviso inexistente
      final deleteInexistente = await dbHelper.deleteAviso(999);
      expect(deleteInexistente, isFalse);
      print('✅ Deleção de ID inexistente retorna false');

      // Inserir aviso com dados mínimos
      final avisoMinimo = Aviso(
        id: 0,
        titulo: 'T',
        mensagem: 'M',
        dataPublicacao: DateTime.now(),
        autorId: 1,
      );
      
      final id = await dbHelper.insertAviso(avisoMinimo);
      expect(id, isNotNull);
      print('✅ Inserção com dados mínimos funciona');

      // Verificar se a busca vazia retorna lista vazia
      await dbHelper.clearDatabase();
      final listaVazia = await dbHelper.getAvisos();
      expect(listaVazia, isEmpty);
      print('✅ Busca em banco vazio retorna lista vazia');
      
      print('✅ Todos os casos extremos testados com sucesso!');
    });
  });
}
