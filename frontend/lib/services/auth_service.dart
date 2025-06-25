import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart'; // Updated import path

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepository;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String _userType = ''; // Add this field

  // Constructor for use with service locator
  AuthService(this._authRepository);

  // Default constructor for backward compatibility
  // This assumes you're using a default implementation internally
  AuthService.fromNoArgs() : _authRepository = AuthRepository(null);

  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userType => _currentUser?.userType ?? _userType; // Add this getter

  // Add development login method
  void devLogin() {
    _userType = 'funcionario'; // Set for dev mode
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authRepository.login(username, password);
      
      if (success) {
        await _loadUser();
      } else {
        _error = 'Falha no login. Verifique suas credenciais.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Erro ao fazer login: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authRepository.logout();
      _currentUser = null;
      _userType = ''; // Clear user type
    } catch (e) {
      _error = 'Erro ao fazer logout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      if (_currentUser == null) {
        _error = 'Não foi possível obter dados do usuário';
      }
    } catch (e) {
      _error = 'Erro ao carregar usuário: $e';
    }
    notifyListeners();
  }
}

// import 'package:flutter/foundation.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'dart:io';
// import 'login_service.dart';

// class AuthService extends ChangeNotifier {
//   final _storage = FlutterSecureStorage();
//   String? _token;
//   String? _userType;
//   bool _isAuthenticated = false;

//   // You can update this with your computer's IP address
//   // Find your IP by running 'ipconfig' on Windows command prompt
//   final String _serverIP = '192.168.1.100'; // Change this to your actual IP address

//   AuthService() {
//     // For development only - auto authenticate
//     _token = 'dev-token';
//     _userType = 'funcionario'; // or 'responsavel' based on what you need to test
//     _isAuthenticated = true;
//   }

//   bool get isAuthenticated => _isAuthenticated;
//   String? get token => _token;
//   String? get userType => _userType;

//   String get baseUrl {
//     // When using a web browser, localhost works fine
//     if (kIsWeb) {
//       return 'http://localhost:8000';
//     }
    
//     // When running on an emulator on Android, the special 10.0.2.2 IP is used to access the host machine
//     if (!kIsWeb && Platform.isAndroid) {
//       try {
//         // This tries to detect if we're on an emulator
//         if (Platform.environment.containsKey('ANDROID_EMU')) {
//           return 'http://10.0.2.2:8000';
//         }
//       } catch (e) {
//         // If there's any error, fall back to the configured IP
//       }
//     }

//     // When running on a physical device, use the computer's actual IP address
//     return 'http://$_serverIP:8000';
//   }

//   Future<void> checkAuth() async {
//     _token = await _storage.read(key: 'token');
//     _userType = await _storage.read(key: 'userType');
//     _isAuthenticated = _token != null;
//     notifyListeners();
//   }

//   Future<bool> login(String email, String password, String userType) async {
//     final loginService = LoginService(baseUrl: baseUrl);
//     final token = await loginService.login(email, password);
    
//     if (token != null) {
//       _token = token;
//       _userType = userType;
//       _isAuthenticated = true;
      
//       // Store token and user type
//       await _storage.write(key: 'token', value: token);
//       await _storage.write(key: 'userType', value: userType);
      
//       notifyListeners();
//       return true;
//     }
    
//     return false;
//   }

//   Future<void> logout() async {
//     _token = null;
//     _userType = null;
//     _isAuthenticated = false;
    
//     // Clear stored values
//     await _storage.delete(key: 'token');
//     await _storage.delete(key: 'userType');
    
//     notifyListeners();
//   }

//   Future<void> devLogin() async {
//     // For development only - simulate a successful login
//     _token = 'dev-token';
//     _userType = 'funcionario'; // or 'responsavel'
//     _isAuthenticated = true;
    
//     // Store values
//     await _storage.write(key: 'token', value: _token);
//     await _storage.write(key: 'userType', value: _userType);
    
//     notifyListeners();
//   }
// }
