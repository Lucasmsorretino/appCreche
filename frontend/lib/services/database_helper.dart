import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Adicionando suporte FFI para plataformas desktop
import '../models/aviso.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  bool _isInitializing = false;
  static const String _logPrefix = '[DatabaseHelper]';
  static const String _databaseName = 'cmei_app_v2.db'; // Nome alterado para forçar nova criação

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    // Evitar múltiplas inicializações simultâneas
    if (_isInitializing) {
      // Aguardar até que a inicialização em andamento termine
      debugPrint('$_logPrefix Aguardando inicialização do banco de dados...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _database;
    }

    if (_database != null) return _database;
    
    if (kIsWeb) {
      debugPrint('$_logPrefix SQLite não funciona na web');
      return null;
    }
    
    try {
      _isInitializing = true;
      
      // Inicializar FFI para suporte a plataformas desktop
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        debugPrint('$_logPrefix Inicializando suporte FFI para SQLite');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      
      _database = await _initDatabase();
      debugPrint('$_logPrefix Banco de dados inicializado com sucesso');
      
      // Verificar se o banco foi criado corretamente
      final tables = await _database?.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
      debugPrint('$_logPrefix Tabelas no banco de dados: $tables');
      
      return _database;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao inicializar banco de dados: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return null;
    } finally {
      _isInitializing = false;
    }
  }
  Future<Database> _initDatabase() async {
    try {
      // Obter o caminho para o diretório do aplicativo
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      
      // Garantir que o diretório existe
      if (!documentsDirectory.existsSync()) {
        await documentsDirectory.create(recursive: true);
        debugPrint('$_logPrefix Diretório de documentos criado: ${documentsDirectory.path}');
      }
      
      String path = join(documentsDirectory.path, _databaseName);
      
      debugPrint('$_logPrefix Caminho do banco de dados: $path');
      
      // Verificar se o arquivo existe
      bool exists = await File(path).exists();
      debugPrint('$_logPrefix Banco de dados já existe? $exists');
      
      // Verificar e remover arquivos WAL/SHM antigos se existirem
      final walFile = File('$path-wal');
      final shmFile = File('$path-shm');
      
      if (await walFile.exists()) {
        try {
          await walFile.delete();
          debugPrint('$_logPrefix Arquivo WAL antigo removido');
        } catch (e) {
          debugPrint('$_logPrefix Erro ao remover arquivo WAL: $e');
        }
      }
      
      if (await shmFile.exists()) {
        try {
          await shmFile.delete();
          debugPrint('$_logPrefix Arquivo SHM antigo removido');
        } catch (e) {
          debugPrint('$_logPrefix Erro ao remover arquivo SHM: $e');
        }
      }
      
      // Se o arquivo existir mas tiver problemas, tentar excluir e recriar
      if (exists) {
        try {
          final testDb = await openDatabase(path, readOnly: true);
          await testDb.close();
        } catch (e) {
          debugPrint('$_logPrefix Banco de dados existente com problemas, recriando...');
          try {
            await File(path).delete();
            exists = false;
          } catch (deleteError) {
            debugPrint('$_logPrefix Erro ao excluir banco corrompido: $deleteError');
            // Tentar criar um nome alternativo
            path = join(documentsDirectory.path, '${_databaseName}_new.db');
            debugPrint('$_logPrefix Tentando usar caminho alternativo: $path');
          }
        }
      }
      
      // Abrir/criar o banco de dados com configurações otimizadas
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          debugPrint('$_logPrefix Banco de dados aberto com sucesso');
          // Ativar chaves estrangeiras
          await db.execute('PRAGMA foreign_keys = ON');
          // Verificar a configuração atual de journal_mode
          final journalMode = await db.rawQuery('PRAGMA journal_mode');
          debugPrint('$_logPrefix Journal Mode: $journalMode');
          // Verificar estrutura do banco para diagnóstico
          _checkDatabaseStructure(db);
        },
        onConfigure: (db) async {
          // Configurar o banco antes da criação/abertura
          await db.execute('PRAGMA journal_mode = WAL'); // Write-Ahead Logging para melhor concorrência
        },
      );
      
      debugPrint('$_logPrefix Banco de dados inicializado com sucesso');
      return db;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao abrir banco de dados: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      rethrow; // Propagar o erro para tratamento adequado
    }
  }

  // Método para atualização de versão
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('$_logPrefix Atualizando banco de dados da versão $oldVersion para $newVersion');
    
    if (oldVersion < 1) {
      // Migração para versão 1
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _checkDatabaseStructure(Database db) async {
    try {
      // Listar tabelas
      final tablesList = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
      debugPrint('$_logPrefix Tabelas encontradas: ${tablesList.map((e) => e['name']).toList()}');
      
      // Verificar estrutura da tabela avisos
      if (tablesList.any((table) => table['name'] == 'avisos')) {
        final avisoColumns = await db.rawQuery('PRAGMA table_info(avisos)');
        debugPrint('$_logPrefix Estrutura da tabela avisos: $avisoColumns');
      } else {
        debugPrint('$_logPrefix ERRO: Tabela avisos não encontrada!');
        // Tentar criar a tabela se não existir
        await _onCreate(db, 1);
      }
    } catch (e) {
      debugPrint('$_logPrefix Erro ao verificar estrutura: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('$_logPrefix Criando tabelas do banco de dados...');
    
    try {
      // Criar a tabela de avisos com campos bem definidos
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
      
      debugPrint('$_logPrefix Tabela avisos criada com sucesso');
      
      // Verificar se a tabela foi realmente criada
      final tableCheck = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table" AND name="avisos"');
      debugPrint('$_logPrefix Verificação da tabela avisos: ${tableCheck.isNotEmpty ? "Criada" : "Falha"}');
      
      if (tableCheck.isEmpty) {
        throw Exception("Falha ao criar tabela avisos");
      }
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro crítico ao criar tabela avisos: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      rethrow;
    }
  }

  // CRUD Operations
  Future<int> insertAviso(Aviso aviso) async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação ignorada na web');
      return -1;
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para inserção');
      return -1;
    }
    
    try {
      final Map<String, dynamic> avisoMap = {
        'id': aviso.id,
        'titulo': aviso.titulo,
        'mensagem': aviso.mensagem,
        'data_publicacao': aviso.dataPublicacao.toIso8601String(),
        'imagem_url': aviso.imagemUrl,
        'autor_id': aviso.autorId,
        'is_synced': 1,
      };
      
      debugPrint('$_logPrefix Inserindo aviso ID: ${aviso.id}, Título: ${aviso.titulo}');
      
      // Verificar se já existe um registro com o mesmo ID
      final existingCheck = await db.query(
        'avisos',
        where: 'id = ?',
        whereArgs: [aviso.id],
      );
      
      if (existingCheck.isNotEmpty) {
        debugPrint('$_logPrefix Aviso ID ${aviso.id} já existe, atualizando...');
      }
      
      final result = await db.insert(
        'avisos',
        avisoMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('$_logPrefix Aviso inserido com sucesso, ID: ${aviso.id}, resultado: $result');
      
      // Verificar se o registro foi realmente inserido
      final inserted = await db.query(
        'avisos',
        where: 'id = ?',
        whereArgs: [aviso.id],
      );
      
      debugPrint('$_logPrefix Verificação pós-inserção: ${inserted.isNotEmpty ? "Sucesso" : "Falha"}');
      if (inserted.isNotEmpty) {
        debugPrint('$_logPrefix Dados inseridos: ${inserted.first}');
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao inserir aviso: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return -1;
    }
  }
  
  // Método específico para inserções offline com flag
  Future<int> insertOfflineAviso(Aviso aviso) async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação offline ignorada na web');
      return -1;
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para inserção offline');
      return -1;
    }
    
    try {
      // Usamos ID negativo para avisos temporários criados offline
      final tempId = aviso.id < 0 ? aviso.id : -DateTime.now().millisecondsSinceEpoch;
      
      final Map<String, dynamic> avisoMap = {
        'id': tempId,
        'titulo': aviso.titulo,
        'mensagem': aviso.mensagem,
        'data_publicacao': aviso.dataPublicacao.toIso8601String(),
        'imagem_url': aviso.imagemUrl,
        'autor_id': aviso.autorId,
        'is_synced': 0, // Marcar como não sincronizado
      };
      
      debugPrint('$_logPrefix Inserindo aviso offline com ID temporário: $tempId');
      
      final result = await db.insert(
        'avisos',
        avisoMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('$_logPrefix Aviso offline inserido, resultado: $result');
      
      // Verificar inserção
      final inserted = await db.query(
        'avisos',
        where: 'id = ?',
        whereArgs: [tempId],
      );
      
      if (inserted.isEmpty) {
        debugPrint('$_logPrefix ALERTA: Falha ao verificar inserção offline');
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao inserir aviso offline: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return -1;
    }
  }

  Future<List<Aviso>> getAvisos() async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação ignorada na web');
      return [];
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para consulta');
      return [];
    }
    
    try {
      debugPrint('$_logPrefix Consultando todos os avisos do banco...');
      final List<Map<String, dynamic>> maps = await db.query('avisos');
      debugPrint('$_logPrefix Avisos encontrados: ${maps.length}');
      
      if (maps.isEmpty) {
        debugPrint('$_logPrefix Nenhum aviso encontrado no banco');
        return [];
      }
      
      return List.generate(maps.length, (i) {
        try {
          return Aviso(
            id: maps[i]['id'],
            titulo: maps[i]['titulo'],
            mensagem: maps[i]['mensagem'],
            dataPublicacao: DateTime.parse(maps[i]['data_publicacao']),
            imagemUrl: maps[i]['imagem_url'],
            autorId: maps[i]['autor_id'],
          );
        } catch (e, stackTrace) {
          debugPrint('$_logPrefix Erro ao converter registro para Aviso: $e');
          debugPrint('$_logPrefix Registro problemático: ${maps[i]}');
          debugPrint('$_logPrefix Stack trace: $stackTrace');
          // Retorna um aviso de erro para não quebrar a lista
          return Aviso(
            id: -999,
            titulo: 'Erro',
            mensagem: 'Erro ao carregar este aviso: ${e.toString().substring(0, 50)}',
            dataPublicacao: DateTime.now(),
            autorId: 0,
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao obter avisos: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return [];
    }
  }
  
  Future<Aviso?> getAviso(int id) async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação ignorada na web: getAviso($id)');
      return null;
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para getAviso($id)');
      return null;
    }
    
    try {
      debugPrint('$_logPrefix Buscando aviso ID: $id');
      final List<Map<String, dynamic>> maps = await db.query(
        'avisos',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        debugPrint('$_logPrefix Aviso ID $id não encontrado');
        return null;
      }
      
      debugPrint('$_logPrefix Aviso ID $id encontrado');
      return Aviso(
        id: maps[0]['id'],
        titulo: maps[0]['titulo'],
        mensagem: maps[0]['mensagem'],
        dataPublicacao: DateTime.parse(maps[0]['data_publicacao']),
        imagemUrl: maps[0]['imagem_url'],
        autorId: maps[0]['autor_id'],
      );
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao buscar aviso ID $id: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return null;
    }
  }
  
  Future<int> updateAviso(Aviso aviso) async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação ignorada na web: updateAviso(${aviso.id})');
      return 0;
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para updateAviso');
      return 0;
    }
    
    try {
      debugPrint('$_logPrefix Atualizando aviso ID: ${aviso.id}');
      final result = await db.update(
        'avisos',
        {
          'titulo': aviso.titulo,
          'mensagem': aviso.mensagem,
          'data_publicacao': aviso.dataPublicacao.toIso8601String(),
          'imagem_url': aviso.imagemUrl,
          'autor_id': aviso.autorId,
          'is_synced': 0, // Mark for sync
        },
        where: 'id = ?',
        whereArgs: [aviso.id],
      );
      
      debugPrint('$_logPrefix Aviso atualizado: ${aviso.id}, linhas afetadas: $result');
      
      // Verificar atualização
      if (result > 0) {
        final updated = await db.query(
          'avisos',
          where: 'id = ?',
          whereArgs: [aviso.id],
        );
        
        if (updated.isNotEmpty) {
          debugPrint('$_logPrefix Verificação pós-atualização: Sucesso');
        } else {
          debugPrint('$_logPrefix ALERTA: Registro não encontrado após atualização');
        }
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao atualizar aviso: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return 0;
    }
  }
  
  Future<int> deleteAviso(int id) async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação ignorada na web: deleteAviso($id)');
      return 0;
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para deleteAviso');
      return 0;
    }
    
    try {
      debugPrint('$_logPrefix Excluindo aviso ID: $id');
      
      // Verificar se o registro existe antes de excluir
      final existingCheck = await db.query(
        'avisos',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (existingCheck.isEmpty) {
        debugPrint('$_logPrefix Aviso ID $id não existe para exclusão');
        return 0;
      }
      
      // Excluir o registro
      final result = await db.delete(
        'avisos',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      debugPrint('$_logPrefix Aviso ID $id deletado, linhas afetadas: $result');
      
      // Verificar exclusão
      final deletedCheck = await db.query(
        'avisos',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (deletedCheck.isEmpty) {
        debugPrint('$_logPrefix Verificação pós-exclusão: Sucesso');
      } else {
        debugPrint('$_logPrefix ALERTA: Registro ainda existe após exclusão');
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao deletar aviso: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return 0;
    }
  }
  
  Future<List<Aviso>> getUnsyncedAvisos() async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação ignorada na web: getUnsyncedAvisos()');
      return [];
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para getUnsyncedAvisos');
      return [];
    }
    
    try {
      debugPrint('$_logPrefix Buscando avisos não sincronizados...');
      final List<Map<String, dynamic>> maps = await db.query(
        'avisos',
        where: 'is_synced = ?',
        whereArgs: [0],
      );
      
      debugPrint('$_logPrefix Encontrados ${maps.length} avisos não sincronizados');
      
      if (maps.isNotEmpty) {
        debugPrint('$_logPrefix IDs dos avisos não sincronizados: ${maps.map((e) => e['id']).toList()}');
      }
      
      return List.generate(maps.length, (i) {
        try {
          return Aviso(
            id: maps[i]['id'],
            titulo: maps[i]['titulo'],
            mensagem: maps[i]['mensagem'],
            dataPublicacao: DateTime.parse(maps[i]['data_publicacao']),
            imagemUrl: maps[i]['imagem_url'],
            autorId: maps[i]['autor_id'],
          );
        } catch (e) {
          debugPrint('$_logPrefix Erro ao converter registro não sincronizado: $e');
          // Retorna um aviso com erro
          return Aviso(
            id: -999,
            titulo: 'Erro',
            mensagem: 'Erro ao carregar aviso não sincronizado',
            dataPublicacao: DateTime.now(),
            autorId: 0,
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao obter avisos não sincronizados: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return [];
    }
  }

  Future<int> markAvisoSynced(int id) async {
    if (kIsWeb) {
      debugPrint('$_logPrefix Operação ignorada na web: markAvisoSynced($id)');
      return 0;
    }
    
    final db = await database;
    if (db == null) {
      debugPrint('$_logPrefix Banco de dados não disponível para markAvisoSynced');
      return 0;
    }
    
    try {
      debugPrint('$_logPrefix Marcando aviso ID $id como sincronizado');
      final result = await db.update(
        'avisos',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      debugPrint('$_logPrefix Aviso ID $id marcado como sincronizado, resultado: $result');
      
      // Verificar atualização
      if (result > 0) {
        final updated = await db.query(
          'avisos',
          where: 'id = ?',
          whereArgs: [id],
        );
        
        if (updated.isNotEmpty) {
          final isSynced = updated.first['is_synced'] == 1;
          debugPrint('$_logPrefix Verificação pós-marcação: ${isSynced ? "Sucesso" : "Falha"}');
        }
      }
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao marcar aviso como sincronizado: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return 0;
    }
  }
  
  // Método para verificar funcionamento do banco
  Future<bool> isDatabaseWorking() async {
    if (kIsWeb) return false;
    
    try {
      debugPrint('$_logPrefix Testando funcionamento do banco de dados...');
      
      final db = await database;
      if (db == null) {
        debugPrint('$_logPrefix ERRO: Banco de dados é nulo!');
        return false;
      }
      
      // Verificar se a tabela avisos existe
      final tableExists = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table" AND name="avisos"');
      
      if (tableExists.isEmpty) {
        debugPrint('$_logPrefix ERRO: Tabela avisos não existe!');
        // Tentar criar a tabela
        await _onCreate(db, 1);
        debugPrint('$_logPrefix Tentativa de criar tabela avisos');
      }
      
      // Tentar fazer uma inserção de teste
      final testId = DateTime.now().millisecondsSinceEpoch;
      final testData = {
        'id': testId,
        'titulo': 'Teste de funcionamento',
        'mensagem': 'Este é um aviso de teste para diagnóstico do banco de dados',
        'data_publicacao': DateTime.now().toIso8601String(),
        'autor_id': 1,
        'is_synced': 0
      };
      
      try {
        debugPrint('$_logPrefix Tentando inserir registro de teste...');
        await db.insert('avisos', testData);
        
        // Verificar se o registro foi inserido
        final result = await db.query('avisos', where: 'id = ?', whereArgs: [testId]);
        
        if (result.isEmpty) {
          debugPrint('$_logPrefix ERRO: Registro de teste não foi encontrado após inserção!');
          return false;
        }
        
        // Excluir o registro de teste
        await db.delete('avisos', where: 'id = ?', whereArgs: [testId]);
        debugPrint('$_logPrefix Teste de banco de dados concluído com sucesso');
        return true;
      } catch (e) {
        debugPrint('$_logPrefix ERRO durante teste de banco: $e');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix ERRO ao testar banco: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return false;
    }
  }

  // Método para inserir dados de teste no banco (útil para debugging)
  Future<bool> insertTestData({bool force = false}) async {
    if (kIsWeb) return false;
    
    try {
      debugPrint('$_logPrefix Inserindo dados de teste...');
      
      final db = await database;
      if (db == null) {
        debugPrint('$_logPrefix ERRO: Banco de dados é nulo!');
        return false;
      }
      
      // Verificar se já existem dados
      if (!force) {
        final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM avisos'));
        if (count != null && count > 0) {
          debugPrint('$_logPrefix Já existem dados no banco ($count registros). Use force=true para inserir mesmo assim.');
          return true;
        }
      }
      
      // Inserir alguns avisos de teste
      final testAvisos = [
        {
          'id': 1001,
          'titulo': 'Reunião de Pais',
          'mensagem': 'Reunião de pais e mestres nesta sexta-feira às 19h.',
          'data_publicacao': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'autor_id': 1,
          'imagem_url': '',
          'is_synced': 1
        },
        {
          'id': 1002,
          'titulo': 'Passeio Escolar',
          'mensagem': 'Passeio ao zoológico na próxima semana. Favor enviar autorização até quarta-feira.',
          'data_publicacao': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'autor_id': 2,
          'imagem_url': '',
          'is_synced': 1
        },
        {
          'id': 1003,
          'titulo': 'Cardápio da Semana',
          'mensagem': 'O cardápio desta semana já está disponível no mural da escola.',
          'data_publicacao': DateTime.now().toIso8601String(),
          'autor_id': 1,
          'imagem_url': '',
          'is_synced': 1
        }
      ];
      
      // Inserir em transação para garantir atomicidade
      await db.transaction((txn) async {
        for (var aviso in testAvisos) {
          // Excluir se já existir (para evitar duplicação)
          await txn.delete('avisos', where: 'id = ?', whereArgs: [aviso['id']]);
          await txn.insert('avisos', aviso);
        }
      });
      
      debugPrint('$_logPrefix ${testAvisos.length} avisos de teste inseridos com sucesso');
      return true;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix ERRO ao inserir dados de teste: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Método para limpar e reiniciar o banco de dados (útil para debugging)  
  Future<bool> resetDatabase() async {
    if (kIsWeb) return false;
    
    try {
      debugPrint('$_logPrefix Resetando banco de dados...');
      
      // Fechar conexão atual
      if (_database != null) {
        await _database!.close();
        debugPrint('$_logPrefix Conexão com banco de dados fechada');
        await Future.delayed(const Duration(milliseconds: 200)); // Pequeno delay para garantir que conexão seja fechada
      }
      
      _database = null;
      
      // Verificar e criar diretório se não existir
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      if (!documentsDirectory.existsSync()) {
        await documentsDirectory.create(recursive: true);
        debugPrint('$_logPrefix Diretório de documentos criado');
      }
      
      // Lista de possíveis nomes de banco de dados para excluir
      final dbNames = [
        'cmei_app_database.db', // Nome antigo
        _databaseName,           // Nome atual
        '${_databaseName}_new.db', // Nome alternativo possível
      ];
      
      // Excluir todos os bancos possíveis
      for (var dbName in dbNames) {
        final dbPath = join(documentsDirectory.path, dbName);
        
        // Tentar excluir arquivo principal
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          try {
            await dbFile.delete();
            debugPrint('$_logPrefix Arquivo $dbName excluído com sucesso');
          } catch (e) {
            debugPrint('$_logPrefix Erro ao excluir $dbName: $e');
          }
        }
        
        // Excluir arquivos WAL e SHM relacionados
        final walFile = File('$dbPath-wal');
        final shmFile = File('$dbPath-shm');
        
        if (await walFile.exists()) {
          try {
            await walFile.delete();
            debugPrint('$_logPrefix Arquivo WAL de $dbName excluído');
          } catch (e) {
            debugPrint('$_logPrefix Erro ao excluir WAL de $dbName: $e');
          }
        }
        
        if (await shmFile.exists()) {
          try {
            await shmFile.delete();
            debugPrint('$_logPrefix Arquivo SHM de $dbName excluído');
          } catch (e) {
            debugPrint('$_logPrefix Erro ao excluir SHM de $dbName: $e');
          }
        }
      }
      
      // Recriar banco
      await Future.delayed(const Duration(milliseconds: 300)); // Pequeno delay para garantir que sistema de arquivos esteja sincronizado
      _database = await _initDatabase();
      
      if (_database == null) {
        debugPrint('$_logPrefix ERRO: Banco não foi recriado corretamente');
        return false;
      }
      
      debugPrint('$_logPrefix Banco de dados recriado com sucesso');
      return true;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao resetar banco: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return false;
    }
  }
}