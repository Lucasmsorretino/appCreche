import '../data/repositories/http_client.dart';
import '../core/constants/api_constants.dart';

class LoginService {
  final HttpClient? _httpClient;
  final String? baseUrl;
  
  // Constructor for use with service locator
  LoginService(this._httpClient) : baseUrl = null;
  
  // Constructor for backward compatibility
  LoginService.withBaseUrl({required this.baseUrl}) : _httpClient = null;
  
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      if (_httpClient != null) {
        // Use HttpClient if available
        final response = await _httpClient!.post(
          ApiConstants.login,
          {
            'username': username,
            'password': password,
          },
        );
        
        return response;
      } else if (baseUrl != null) {
        // Use direct HTTP calls for backward compatibility
        // Implement this if needed
        return null;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
}



// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class LoginService {
//   final String baseUrl;

//   LoginService({required this.baseUrl});

//   Future<String?> login(String email, String password) async {
//     final url = Uri.parse('$baseUrl/login');

//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'username': email,
//         'password': password,
//       }),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['access_token'];
//     } else {
//       return null;
//     }
//   }
// }

