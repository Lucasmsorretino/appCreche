import 'package:flutter/material.dart';
import '../services/avisos_service.dart';
import '../models/aviso.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AvisosPage extends StatefulWidget {
  @override
  _AvisosPageState createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> {
  Future<List<Aviso>>? _avisosFuture;
  late AvisosService _avisosService;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_avisosFuture == null) {
      _avisosService = Provider.of<AvisosService>(context, listen: false);
      _loadAvisos();
    }
  }
  
  void _loadAvisos() {
    setState(() {
      _avisosFuture = _avisosService.getAvisos();
    });
  }
  
  // Função para forçar recarga
  Future<void> _refreshAvisos() async {
    setState(() {
      _avisosFuture = _avisosService.getAvisos();
    });
    return _avisosFuture;
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isFuncionario = authService.userType == 'funcionario';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Avisos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAvisos,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAvisos,
        child: FutureBuilder<List<Aviso>>(
          future: _avisosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar avisos: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text('Nenhum aviso disponível'),
              );
            } else {
              final avisos = snapshot.data!;
              return ListView.builder(
                itemCount: avisos.length,
                itemBuilder: (context, index) {
                  final aviso = avisos[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(aviso.titulo),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aviso.mensagem),
                          SizedBox(height: 4),
                          Text(
                            'Publicado em: ${_formatDate(aviso.dataPublicacao)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: isFuncionario ? FloatingActionButton(
        onPressed: () {
          // TODO: Add new announcement (for staff only)
        },
        child: Icon(Icons.add),
      ) : null,
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}