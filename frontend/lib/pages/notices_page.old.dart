import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/avisos_service.dart';
import '../models/aviso.dart';

// Classe auxiliar para compatibilidade com UI legado
class Notice {
  final int id;
  final String title;
  final String content;
  final DateTime date;
  final String author;
  final String? imageUrl;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    this.imageUrl,
  });
  
  // Converter Aviso para Notice
  factory Notice.fromAviso(Aviso aviso) {
    return Notice(
      id: aviso.id,
      title: aviso.titulo,
      content: aviso.mensagem,
      date: aviso.dataPublicacao,
      author: 'Autor ID: ${aviso.autorId}',
      imageUrl: aviso.imagemUrl,
    );
  }
}

class NoticesPage extends StatefulWidget {
  @override
  _NoticesPageState createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  // Lista de avisos
  List<Aviso> _avisos = [];
  List<Notice> _notices = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvisos();
  }
  
  Future<void> _loadAvisos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final avisosService = Provider.of<AvisosService>(context, listen: false);
      final avisos = await avisosService.getAvisos();
      
      setState(() {
        _avisos = avisos;
        _notices = avisos.map((aviso) => Notice.fromAviso(aviso)).toList();
        _isLoading = false;
      });
      
      debugPrint('Avisos carregados: ${avisos.length}');
    } catch (e) {
      debugPrint('Erro ao carregar avisos: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar avisos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _syncAvisos() async {
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final avisosService = Provider.of<AvisosService>(context, listen: false);
      await avisosService.syncAvisos();
      
      // Recarregar após sincronização
      await _loadAvisos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sincronização concluída com sucesso')),
      );
    } catch (e) {
      debugPrint('Erro na sincronização: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na sincronização: ${e.toString().substring(0, 50)}')),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _refreshNotices() async {
    await _loadAvisos();
    
    // Após carregar, tentar sincronizar em segundo plano
    _syncAvisos();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isFuncionario = authService.userType == 'funcionario';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Avisos'),
        actions: [
          if (_isSyncing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20, 
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshNotices,
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _syncAvisos,
            tooltip: 'Sincronizar com servidor',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _notices.isEmpty
                  ? _buildEmptyState()
                  : _buildNoticesList(),
      floatingActionButton: isFuncionario
          ? FloatingActionButton(
              onPressed: () => _showAddNoticeDialog(context),
              child: Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Erro ao carregar avisos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshNotices,
            child: Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum aviso disponível',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              // Inserir avisos de teste diretamente
              final avisosService = Provider.of<AvisosService>(context, listen: false);
              
              try {
                final aviso = Aviso(
                  id: DateTime.now().millisecondsSinceEpoch,
                  titulo: 'Aviso de teste',
                  mensagem: 'Este é um aviso de teste criado diretamente do app.',
                  dataPublicacao: DateTime.now(),
                  autorId: 1,
                  imagemUrl: null,
                );
                
                await avisosService.createAviso(aviso);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Aviso de teste criado com sucesso')),
                );
                
                _refreshNotices();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao criar aviso de teste: $e')),
                );
              }
            },
            child: Text('Criar aviso de teste'),
          ),
        ],
      ),
    );
  }
    Widget _buildNoticesList() {
    return RefreshIndicator(
      onRefresh: _refreshNotices,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              if (notice.imageUrl != null)
                Image.network(
                  notice.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                    );
                  },
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(notice.content),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Por: ${notice.author}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(notice.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Provider.of<AuthService>(context).userType == 'funcionario'
                            ? TextButton(
                                onPressed: () => _showEditNoticeDialog(context, notice),
                                child: Text('Editar'),
                              )
                            : Container(),
                        Provider.of<AuthService>(context).userType == 'funcionario'
                            ? TextButton(
                                onPressed: () => _deleteNotice(notice.id),
                                child: Text('Excluir', style: TextStyle(color: Colors.red)),
                              )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _deleteNotice(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir este aviso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notices.removeWhere((notice) => notice.id == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Aviso excluído com sucesso')),
              );
            },
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showAddNoticeDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final authorController = TextEditingController(
      text: 'Funcionário(a) ${Provider.of<AuthService>(context, listen: false).userType}',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Aviso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Conteúdo',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: InputDecoration(
                  labelText: 'Autor',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                setState(() {
                  _notices.add(
                    Notice(
                      id: _notices.isNotEmpty ? _notices.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1 : 1,
                      title: titleController.text,
                      content: contentController.text,
                      date: DateTime.now(),
                      author: authorController.text,
                      imageUrl: null,
                    ),
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Aviso adicionado com sucesso')),
                );
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  void _showEditNoticeDialog(BuildContext context, Notice notice) {
    final titleController = TextEditingController(text: notice.title);
    final contentController = TextEditingController(text: notice.content);
    final authorController = TextEditingController(text: notice.author);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Aviso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Conteúdo',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: InputDecoration(
                  labelText: 'Autor',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                setState(() {
                  final index = _notices.indexWhere((n) => n.id == notice.id);
                  if (index != -1) {
                    _notices[index] = Notice(
                      id: notice.id,
                      title: titleController.text,
                      content: contentController.text,
                      date: notice.date,
                      author: authorController.text,
                      imageUrl: notice.imageUrl,
                    );
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Aviso atualizado com sucesso')),
                );
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
