import 'dart:convert';
import 'package:http/http.dart' as http_package;
import '../core/constants/api_constants.dart';
import '../data/repositories/http_client.dart';
import '../models/routine_model.dart';
import 'database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RotinaService {
  final HttpClient _httpClient;
  final DatabaseHelper _databaseHelper;
  final Connectivity _connectivity = Connectivity();
  
  RotinaService(this._httpClient, this._databaseHelper);
  
  Future<Map<String, dynamic>> salvarRotina(Map<String, dynamic> rotina) async {
    try {
      final response = await _httpClient.post(
        ApiConstants.rotinas,
        rotina
      );
      
      return response;
    } catch (e) {
      print('Erro ao salvar rotina: $e');
      throw Exception('Falha ao salvar rotina: $e');
    }
  }
  
  // Add other rotina-related methods here
  Future<List<dynamic>> obterRotinas() async {
    try {
      final response = await _httpClient.get(ApiConstants.rotinas);
      return response;
    } catch (e) {
      print('Erro ao obter rotinas: $e');
      return [];
    }
  }
}




// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/routine_model.dart';

// class RoutineService {
//   final String baseUrl;
//   final String authToken;

//   RoutineService({required this.baseUrl, required this.authToken});

//   Future<bool> submitRoutine(RoutineModel routine) async {
//     final url = Uri.parse('$baseUrl/rotina');
//     final response = await http.post(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $authToken',
//       },
//       body: jsonEncode(routine.toJson()),
//     );

//     return response.statusCode == 200 || response.statusCode == 201;
//   }
// }
