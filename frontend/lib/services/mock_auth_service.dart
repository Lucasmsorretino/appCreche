import 'package:flutter/foundation.dart';

/// Serviço de autenticação mock para desenvolvimento e testes
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  // Usuário mock para desenvolvimento
  static const mockUser = {
    'id': 1,
    'name': 'Usuário Desenvolvedor',
    'email': 'dev@cmei.com',
    'role': 'admin',
  };

  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;

  /// Autentica com usuário mock (para desenvolvimento)
  Future<bool> authenticateAsDeveloper() async {
    try {
      _isAuthenticated = true;
      _currentUser = Map.from(mockUser);
      debugPrint('[MockAuthService] Autenticado como desenvolvedor: ${_currentUser!['name']}');
      return true;
    } catch (e) {
      debugPrint('[MockAuthService] Erro na autenticação mock: $e');
      return false;
    }
  }

  /// Autentica com credenciais reais (implementar quando necessário)
  Future<bool> authenticate(String email, String password) async {
    // Para desenvolvimento, aceitar qualquer credencial
    if (kDebugMode) {
      return await authenticateAsDeveloper();
    }
    
    // TODO: Implementar autenticação real
    return false;
  }

  /// Faz logout
  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    debugPrint('[MockAuthService] Logout realizado');
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _isAuthenticated;

  /// Retorna o usuário atual
  Map<String, dynamic>? get currentUser => _currentUser;

  /// Retorna o ID do usuário atual (ou ID padrão para desenvolvimento)
  int get currentUserId {
    if (_currentUser != null) {
      return _currentUser!['id'] ?? 1;
    }
    return 1; // ID padrão para desenvolvimento
  }

  /// Retorna o nome do usuário atual
  String get currentUserName {
    if (_currentUser != null) {
      return _currentUser!['name'] ?? 'Usuário';
    }
    return 'Usuário Desenvolvedor';
  }

  /// Retorna o email do usuário atual
  String get currentUserEmail {
    if (_currentUser != null) {
      return _currentUser!['email'] ?? 'dev@cmei.com';
    }
    return 'dev@cmei.com';
  }

  /// Verifica se o usuário tem permissão de admin
  bool get isAdmin {
    if (_currentUser != null) {
      return _currentUser!['role'] == 'admin';
    }
    return true; // Para desenvolvimento, sempre admin
  }

  /// Inicializa o serviço (chama automaticamente autenticação para dev)
  Future<void> initialize() async {
    if (kDebugMode) {
      await authenticateAsDeveloper();
    }
  }
}
