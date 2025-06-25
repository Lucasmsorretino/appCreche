// Arquivo de diagnóstico do SQLite
// Execute este arquivo separadamente para diagnosticar problemas de banco de dados

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Inicializar suporte a SQLite FFI
  print('Inicializando suporte a SQLite FFI...');
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('\n=== DIAGNÓSTICO DO BANCO DE DADOS SQLITE ===');
  
  try {
    // Verificar diretório de documentos
    final documentsDir = await getApplicationDocumentsDirectory();
    print('\nDiretório de documentos: ${documentsDir.path}');
    
    // Verificar se o diretório existe
    if (!documentsDir.existsSync()) {
      print('ERRO: Diretório de documentos não existe!');
      print('Tentando criar diretório...');
      try {
        await documentsDir.create(recursive: true);
        print('Diretório de documentos criado com sucesso.');
      } catch (e) {
        print('ERRO ao criar diretório: $e');
      }
    }
    
    // Listar todos os arquivos no diretório
    final dirContents = documentsDir.listSync();
    print('\nArquivos no diretório:');
    for (var entity in dirContents) {
      if (entity is File) {
        final size = await entity.length();
        print('  - ${basename(entity.path)} (${size} bytes)');
      } else {
        print('  - ${basename(entity.path)} (diretório)');
      }
    }
    
    // Verificar nomes possíveis de banco de dados
    final dbNames = [
      'cmei_app_database.db',
      'cmei_app_v2.db',
    ];
    
    print('\nVerificando bancos de dados:');
    for (var dbName in dbNames) {
      final dbPath = join(documentsDir.path, dbName);
      final exists = await File(dbPath).exists();
      print('  - $dbName: ${exists ? "Existe" : "Não existe"}');
      
      if (exists) {
        final size = await File(dbPath).length();
        print('    Tamanho: $size bytes');
        
        // Verificar permissões
        try {
          print('    Verificando permissões...');
          final file = File(dbPath);
          bool canRead = await file.exists();
          print('    Pode ler: $canRead');
          
          // Tentar abrir o arquivo para leitura
          try {
            final randomAccessFile = await file.open(mode: FileMode.read);
            await randomAccessFile.close();
            print('    Arquivo pode ser aberto para leitura: Sim');
          } catch (e) {
            print('    ERRO ao abrir arquivo para leitura: $e');
          }
          
          // Tentar abrir o arquivo para escrita
          try {
            final testFile = File('${dbPath}_test');
            await testFile.writeAsString('test');
            final canWrite = await testFile.exists();
            print('    Pode escrever no diretório: $canWrite');
            if (canWrite) {
              await testFile.delete();
            }
          } catch (e) {
            print('    ERRO ao testar escrita: $e');
          }
        } catch (e) {
          print('    ERRO ao verificar permissões: $e');
        }
        
        // Verificar arquivos relacionados
        final walPath = '$dbPath-wal';
        final shmPath = '$dbPath-shm';
        final walExists = await File(walPath).exists();
        final shmExists = await File(shmPath).exists();
        
        print('    Arquivo WAL: ${walExists ? "Existe" : "Não existe"}');
        print('    Arquivo SHM: ${shmExists ? "Existe" : "Não existe"}');
        
    // Tentar abrir o banco
        try {
          print('    Tentando abrir o banco...');
          final db = await openDatabase(dbPath);
          
          // Verificar tabelas
          final tables = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
          print('    Tabelas: ${tables.map((t) => t['name']).toList()}');
          
          // Se tiver a tabela avisos, verificar contagem
          if (tables.any((t) => t['name'] == 'avisos')) {
            final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM avisos'));
            print('    Contagem de avisos: $count');
            
            if (count! > 0) {
              final first = await db.query('avisos', limit: 1);
              print('    Primeiro aviso: $first');
            }
            
            // Realizar teste de escrita/leitura
            print('\n    Realizando teste de escrita/leitura...');
            final testId = DateTime.now().millisecondsSinceEpoch;
            final testData = {
              'id': testId,
              'titulo': 'Teste de diagnóstico',
              'mensagem': 'Teste de escrita/leitura no SQLite',
              'data_publicacao': DateTime.now().toIso8601String(),
              'autor_id': 999,
              'is_synced': 0
            };
            
            try {
              print('    Inserindo registro de teste...');
              await db.insert('avisos', testData);
              
              // Verificar se o registro foi inserido
              print('    Verificando registro inserido...');
              final result = await db.query('avisos', where: 'id = ?', whereArgs: [testId]);
              
              if (result.isNotEmpty) {
                print('    Sucesso: Registro de teste encontrado!');
                print('    Dados: ${result.first}');
                
                // Excluir o registro de teste
                await db.delete('avisos', where: 'id = ?', whereArgs: [testId]);
                print('    Registro de teste excluído com sucesso');
              } else {
                print('    FALHA: Registro não foi encontrado após inserção!');
              }
            } catch (writeError) {
              print('    ERRO durante teste de escrita/leitura: $writeError');
            }
          } else {
            print('    AVISO: Tabela avisos não encontrada. Tentando criar...');
            try {
              await db.execute('''
                CREATE TABLE IF NOT EXISTS avisos (
                  id INTEGER PRIMARY KEY,
                  titulo TEXT NOT NULL,
                  mensagem TEXT NOT NULL,
                  data_publicacao TEXT NOT NULL,
                  imagem_url TEXT,
                  autor_id INTEGER NOT NULL,
                  is_synced INTEGER DEFAULT 1
                )
              ''');
              print('    Tabela avisos criada com sucesso.');
            } catch (createError) {
              print('    ERRO ao criar tabela: $createError');
            }
          }
          
          // Verificar permissões de journal_mode
          final journalMode = await db.rawQuery('PRAGMA journal_mode');
          print('    Journal mode: $journalMode');
          
          await db.close();
          print('    Banco fechado com sucesso');
        } catch (e) {
          print('    ERRO ao abrir banco: $e');
          
          // Tentar excluir o banco corrompido
          print('    Tentando excluir banco possivelmente corrompido...');
          try {
            await File(dbPath).delete();
            if (walExists) await File(walPath).delete();
            if (shmExists) await File(shmPath).delete();
            print('    Banco excluído com sucesso');
          } catch (e) {
            print('    ERRO ao excluir banco: $e');
          }
        }
      }
    }
      print('\nCriando banco de teste...');
    final testDbPath = join(documentsDir.path, 'teste_diagnostico.db');
    
    // Excluir se já existir
    if (await File(testDbPath).exists()) {
      await File(testDbPath).delete();
    }
    
    // Verificar se há arquivos WAL ou SHM antigos
    final testWalPath = '$testDbPath-wal';
    final testShmPath = '$testDbPath-shm';
    if (await File(testWalPath).exists()) {
      await File(testWalPath).delete();
      print('  Arquivo WAL antigo excluído');
    }
    if (await File(testShmPath).exists()) {
      await File(testShmPath).delete();
      print('  Arquivo SHM antigo excluído');
    }
    // Criar banco de teste
    final db = await openDatabase(
      testDbPath,
      version: 1,
      onCreate: (db, version) async {
        print('  Criando tabela de teste...');
        await db.execute('CREATE TABLE IF NOT EXISTS teste (id INTEGER PRIMARY KEY, nome TEXT)');
      },
    );
    
    // Inserir dados de teste
    print('  Inserindo registro de teste...');
    await db.insert('teste', {'id': 1, 'nome': 'Teste de diagnóstico'});
    
    // Verificar se o registro foi inserido
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM teste'));
    print('  Contagem de registros: $count');
    
    // Fechar banco
    await db.close();
    print('  Banco de teste fechado com sucesso');
    
    // Excluir banco de teste
    await File(testDbPath).delete();
    print('  Banco de teste excluído com sucesso');
    
    print('\nDiagnóstico concluído sem erros');
  } catch (e, stack) {
    print('\nERRO DURANTE DIAGNÓSTICO: $e');
    print('Stack trace: $stack');
  }
}
