import '../../models/user_model.dart';  // Updated import path
import 'http_client.dart';
import '../../core/constants/api_constants.dart';

class AuthRepository {
  final HttpClient? _httpClient;
  
  AuthRepository(this._httpClient);
  
  Future<bool> login(String username, String password) async {
    if (_httpClient == null) return false;
    
    try {
      final response = await _httpClient!.post(
        ApiConstants.login, 
        {
          'username': username,
          'password': password,
        }
      );
      
      if (response != null && response['access_token'] != null) {
        await _httpClient!.setToken(response['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    if (_httpClient != null) {
      await _httpClient!.clearToken();
    }
  }
  
  Future<User?> getCurrentUser() async {
    if (_httpClient == null) return null;
    
    try {
      final userData = await _httpClient!.get('/users/me');
      return User.fromJson(userData);
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
}