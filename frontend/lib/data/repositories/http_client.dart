import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';

class HttpClient {
  final http.Client _client = http.Client();
  final _storage = const FlutterSecureStorage();
  static const String _logPrefix = '[HttpClient]';

  // Get authentication token
  Future<String?> _getToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      debugPrint('$_logPrefix Erro ao ler token: $e');
      return null;
    }
  }

  // Set authentication token
  Future<void> setToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
      debugPrint('$_logPrefix Token de autenticação armazenado com sucesso');
    } catch (e) {
      debugPrint('$_logPrefix Erro ao armazenar token: $e');
      rethrow;
    }
  }

  // Clear authentication token (logout)
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'auth_token');
      debugPrint('$_logPrefix Token de autenticação removido com sucesso');
    } catch (e) {
      debugPrint('$_logPrefix Erro ao remover token: $e');
      rethrow;
    }
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$endpoint';
    
    debugPrint('$_logPrefix Enviando GET para $url');
    
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: ApiConstants.timeout));
      
      debugPrint('$_logPrefix Resposta GET de $endpoint - Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('$_logPrefix Conteúdo da resposta: ${response.body.substring(0, min(100, response.body.length))}${response.body.length > 100 ? "..." : ""}');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('$_logPrefix Erro de conexão (GET $endpoint): $e');
      throw Exception('Erro de conexão: Servidor indisponível ou sem internet');
    } on TimeoutException catch (e) {
      debugPrint('$_logPrefix Timeout (GET $endpoint): $e');
      throw Exception('Timeout: Servidor demorando muito para responder');
    } catch (e) {
      debugPrint('$_logPrefix Erro na requisição GET para $endpoint: $e');
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$endpoint';
    
    debugPrint('$_logPrefix Enviando POST para $url');
    debugPrint('$_logPrefix Dados: ${jsonEncode(data)}');
    
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(Duration(seconds: ApiConstants.timeout));
      
      debugPrint('$_logPrefix Resposta POST de $endpoint - Status: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('$_logPrefix Conteúdo da resposta: ${response.body.substring(0, min(100, response.body.length))}${response.body.length > 100 ? "..." : ""}');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('$_logPrefix Erro de conexão (POST $endpoint): $e');
      throw Exception('Erro de conexão: Servidor indisponível ou sem internet');
    } on TimeoutException catch (e) {
      debugPrint('$_logPrefix Timeout (POST $endpoint): $e');
      throw Exception('Timeout: Servidor demorando muito para responder');
    } catch (e) {
      debugPrint('$_logPrefix Erro na requisição POST para $endpoint: $e');
      rethrow;
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$endpoint';
    
    debugPrint('$_logPrefix Enviando PUT para $url');
    debugPrint('$_logPrefix Dados: ${jsonEncode(data)}');
    
    try {
      final response = await _client.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(Duration(seconds: ApiConstants.timeout));
      
      debugPrint('$_logPrefix Resposta PUT de $endpoint - Status: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('$_logPrefix Conteúdo da resposta: ${response.body.substring(0, min(100, response.body.length))}${response.body.length > 100 ? "..." : ""}');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('$_logPrefix Erro de conexão (PUT $endpoint): $e');
      throw Exception('Erro de conexão: Servidor indisponível ou sem internet');
    } on TimeoutException catch (e) {
      debugPrint('$_logPrefix Timeout (PUT $endpoint): $e');
      throw Exception('Timeout: Servidor demorando muito para responder');
    } catch (e) {
      debugPrint('$_logPrefix Erro na requisição PUT para $endpoint: $e');
      rethrow;
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}$endpoint';
    
    debugPrint('$_logPrefix Enviando DELETE para $url');
    
    try {
      final response = await _client.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: ApiConstants.timeout));
      
      debugPrint('$_logPrefix Resposta DELETE de $endpoint - Status: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('$_logPrefix Conteúdo da resposta: ${response.body.substring(0, min(100, response.body.length))}${response.body.length > 100 ? "..." : ""}');
      }
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('$_logPrefix Erro de conexão (DELETE $endpoint): $e');
      throw Exception('Erro de conexão: Servidor indisponível ou sem internet');
    } on TimeoutException catch (e) {
      debugPrint('$_logPrefix Timeout (DELETE $endpoint): $e');
      throw Exception('Timeout: Servidor demorando muito para responder');
    } catch (e) {
      debugPrint('$_logPrefix Erro na requisição DELETE para $endpoint: $e');
      rethrow;
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          final result = jsonDecode(utf8.decode(response.bodyBytes));
          debugPrint('$_logPrefix Resposta processada com sucesso');
          return result;
        } catch (e) {
          debugPrint('$_logPrefix Erro ao decodificar JSON: $e');
          debugPrint('$_logPrefix Body: ${response.body.substring(0, min(100, response.body.length))}${response.body.length > 100 ? "..." : ""}');
          throw Exception('Erro ao processar resposta do servidor');
        }
      }
      debugPrint('$_logPrefix Resposta sem conteúdo');
      return null;
    } else if (response.statusCode == 401) {
      debugPrint('$_logPrefix Erro de autenticação: ${response.body}');
      // Clear token and throw authentication error
      clearToken();
      throw Exception('Falha de autenticação: Sessão expirada ou credenciais inválidas');
    } else {
      debugPrint('$_logPrefix Erro na requisição: ${response.statusCode} - ${response.body}');
      throw Exception('Erro na API: ${response.statusCode} - ${getErrorMessage(response)}');
    }
  }
  
  // Extrai mensagem de erro útil da resposta
  String getErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Erro desconhecido (código ${response.statusCode})';
    }
    
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('detail')) {
        return decoded['detail'].toString();
      } else if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    
    // Se não conseguir extrair mensagem específica
    return 'Erro código ${response.statusCode}';
  }
  
  // Verificar se o backend está disponível  
  Future<bool> isBackendAvailable() async {
    try {
      debugPrint('$_logPrefix Verificando disponibilidade do backend...');
      
      // Tenta acessar o endpoint de saúde com timeout curto
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.health}'),
      ).timeout(const Duration(seconds: 5));
      
      final isAvailable = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint('$_logPrefix Backend disponível: $isAvailable (Status: ${response.statusCode})');
      
      if (isAvailable) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('$_logPrefix Status do backend: ${data['status']}');
          
          // Verificar estrutura da resposta do novo healthcheck
          if (data['database'] != null && data['database'] is Map) {
            final dbInfo = data['database'];
            final dbConnected = dbInfo['status'] == 'connected';
            
            debugPrint('$_logPrefix Banco de dados do backend: ${dbConnected ? "Conectado" : "Desconectado"}');
            debugPrint('$_logPrefix Latência do banco: ${dbInfo['latency_ms']} ms');
            
            // Imprimir estatísticas do banco para diagnóstico
            if (data['db_stats'] != null) {
              final stats = data['db_stats'];
              final tables = stats['tables'];
              final recordCounts = stats['record_counts'];
              
              debugPrint('$_logPrefix Tabelas no banco: $tables');
              if (recordCounts != null && recordCounts is Map) {
                debugPrint('$_logPrefix Contagem de registros: $recordCounts');
              }
            }
            
            return dbConnected; // O backend só está realmente disponível se o banco estiver conectado
          } else {
            // Formato antigo da resposta
            final dbConnected = data['database'] == 'connected';
            debugPrint('$_logPrefix Banco de dados do backend conectado: $dbConnected');
            return dbConnected;
          }
        } catch (e, stackTrace) {
          debugPrint('$_logPrefix Erro ao decodificar resposta de saúde: $e');
          debugPrint('$_logPrefix Stack trace: $stackTrace');
          // Se não conseguir decodificar, pelo menos o endpoint está online
          return true;
        }
      }
      
      return isAvailable;
    } on SocketException catch (e) {
      debugPrint('$_logPrefix Backend indisponível (erro de conexão): $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('$_logPrefix Backend indisponível (timeout): $e');
      return false;
    } catch (e, stackTrace) {
      debugPrint('$_logPrefix Erro ao verificar backend: $e');
      debugPrint('$_logPrefix Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Helper para min Int
  int min(int a, int b) {
    return a < b ? a : b;
  }
}