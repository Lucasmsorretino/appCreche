import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/aviso.dart';

/// Versão do DatabaseHelper específica para testes
/// Usa banco de dados em memória para evitar dependências de plugins nativos
class DatabaseHelperTest {
  static final DatabaseHelperTest _instance = DatabaseHelperTest._internal();
  static Database? _database;
  bool _isInitializing = false;
  static const String _logPrefix = '[DatabaseHelperTest]';

  factory DatabaseHelperTest() => _instance;

  DatabaseHelperTest._internal();

  /// Inicializa o banco de dados para testes
  static Future<void> initializeForTest() async {
    // Inicializar FFI para testes
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database?> get database async {
    if (_isInitializing) {
      debugPrint('$_logPrefix Aguardando inicialização do banco de dados...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _database;
    }

    if (_database != null) return _database;
    
    try {
      _isInitializing = true;
      _database = await _initDatabase();
      debugPrint('$_logPrefix Banco de dados de teste inicializado com sucesso');
      return _database;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao inicializar banco de dados de teste: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return null;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> _initDatabase() async {
    // Usar banco em memória para testes
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        debugPrint('$_logPrefix Banco de dados em memória aberto com sucesso');
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('$_logPrefix Criando tabelas do banco de dados...');
    
    try {
      // Criar tabela de avisos
      await db.execute('''
        CREATE TABLE avisos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          author_id INTEGER,
          synced INTEGER DEFAULT 0
        )
      ''');
      
      debugPrint('$_logPrefix Tabela avisos criada com sucesso');
      
      // Criar outras tabelas conforme necessário
      await _createOtherTables(db);
      
      debugPrint('$_logPrefix Todas as tabelas criadas com sucesso');
    } catch (e) {
      debugPrint('$_logPrefix Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  Future<void> _createOtherTables(Database db) async {
    // Criar tabela de usuários
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        role TEXT DEFAULT 'parent',
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Criar tabela de rotinas
    await db.execute('''
      CREATE TABLE routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_consumed TEXT NOT NULL,
        quantity TEXT NOT NULL,
        observation TEXT,
        created_at TEXT NOT NULL,
        user_id INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Criar tabela de saúde
    await db.execute('''
      CREATE TABLE health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_name TEXT NOT NULL,
        temperature REAL,
        symptoms TEXT,
        medication TEXT,
        observation TEXT,
        created_at TEXT NOT NULL,
        user_id INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Criar tabela de calendário
    await db.execute('''
      CREATE TABLE calendar_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        event_date TEXT NOT NULL,
        event_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        user_id INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }
  // CRUD para Avisos
  Future<int?> insertAviso(Aviso aviso) async {
    final db = await database;
    if (db == null) return null;

    try {
      final avisoMap = {
        'title': aviso.titulo,
        'content': aviso.mensagem,
        'created_at': aviso.dataPublicacao.toIso8601String(),
        'author_id': aviso.autorId,
        'synced': 0,
      };
      final id = await db.insert('avisos', avisoMap);
      debugPrint('$_logPrefix Aviso inserido com ID: $id');
      return id;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao inserir aviso: $e');
      return null;
    }
  }

  Future<List<Aviso>> getAvisos() async {
    final db = await database;
    if (db == null) return [];

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'avisos',
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return Aviso(
          id: maps[i]['id'],
          titulo: maps[i]['title'],
          mensagem: maps[i]['content'],
          dataPublicacao: DateTime.parse(maps[i]['created_at']),
          autorId: maps[i]['author_id'],
          imagemUrl: null,
        );
      });
    } catch (e) {
      debugPrint('$_logPrefix Erro ao buscar avisos: $e');
      return [];
    }
  }

  Future<Aviso?> getAvisoById(int id) async {
    final db = await database;
    if (db == null) return null;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'avisos',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        final map = maps.first;
        return Aviso(
          id: map['id'],
          titulo: map['title'],
          mensagem: map['content'],
          dataPublicacao: DateTime.parse(map['created_at']),
          autorId: map['author_id'],
          imagemUrl: null,
        );
      }
      return null;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao buscar aviso por ID: $e');
      return null;
    }
  }

  Future<bool> updateAviso(Aviso aviso) async {
    final db = await database;
    if (db == null) return false;

    try {
      final avisoMap = {
        'title': aviso.titulo,
        'content': aviso.mensagem,
        'created_at': aviso.dataPublicacao.toIso8601String(),
        'author_id': aviso.autorId,
      };
      final count = await db.update(
        'avisos',
        avisoMap,
        where: 'id = ?',
        whereArgs: [aviso.id],
      );
      debugPrint('$_logPrefix Aviso atualizado. Linhas afetadas: $count');
      return count > 0;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao atualizar aviso: $e');
      return false;
    }
  }

  Future<bool> deleteAviso(int id) async {
    final db = await database;
    if (db == null) return false;

    try {
      final count = await db.delete(
        'avisos',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('$_logPrefix Aviso deletado. Linhas afetadas: $count');
      return count > 0;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao deletar aviso: $e');
      return false;
    }
  }

  /// Limpa o banco de dados (útil para testes)
  Future<void> clearDatabase() async {
    final db = await database;
    if (db == null) return;

    try {
      await db.delete('avisos');
      await db.delete('users');
      await db.delete('routines');
      await db.delete('health_records');
      await db.delete('calendar_events');
      debugPrint('$_logPrefix Banco de dados limpo');
    } catch (e) {
      debugPrint('$_logPrefix Erro ao limpar banco de dados: $e');
    }
  }

  /// Fecha o banco de dados
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      debugPrint('$_logPrefix Banco de dados fechado');
    }
  }
  /// Reseta a instância (útil para testes)
  static void reset() {
    _database = null;
    _instance._isInitializing = false;
  }
}
