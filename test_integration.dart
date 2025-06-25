import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMEI Test',
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _result = 'Pressione o botão para testar a conexão';
  bool _loading = false;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _result = 'Testando conexão...';
    });

    try {
      // Testar health check
      final healthResponse = await http.get(
        Uri.parse('http://localhost:8000/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (healthResponse.statusCode == 200) {
        setState(() {
          _result = 'Backend funcionando!\n\n';
        });

        // Testar login
        final loginResponse = await http.post(
          Uri.parse('http://localhost:8000/token'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'username=lucas&password=senha123',
        );

        if (loginResponse.statusCode == 200) {
          final tokenData = json.decode(loginResponse.body);
          final token = tokenData['access_token'];
          
          setState(() {
            _result += 'Login funcionando!\nToken: ${token.substring(0, 20)}...\n\n';
          });

          // Testar avisos
          final avisosResponse = await http.get(
            Uri.parse('http://localhost:8000/avisos'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (avisosResponse.statusCode == 200) {
            final avisos = json.decode(avisosResponse.body);
            setState(() {
              _result += 'Avisos funcionando!\nEncontrados ${avisos.length} avisos:\n';
              for (var aviso in avisos) {
                _result += '- ${aviso['title']}\n';
              }
            });
          } else {
            setState(() {
              _result += 'Erro ao buscar avisos: ${avisosResponse.statusCode}';
            });
          }
        } else {
          setState(() {
            _result += 'Erro no login: ${loginResponse.statusCode}';
          });
        }
      } else {
        setState(() {
          _result = 'Backend não está respondendo: ${healthResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste de Integração CMEI'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _testConnection,
              child: _loading 
                ? CircularProgressIndicator()
                : Text('Testar Conexão com Backend'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
