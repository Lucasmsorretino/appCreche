import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/aviso.dart';
import '../services/avisos_service.dart';
import '../services/mock_auth_service.dart';

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
  bool _isSyncing = false;  String? _errorMessage;
  
  // Getter para verificar se é funcionário
  bool get _isFuncionario {
    // Para desenvolvimento, sempre permitir ações de admin
    // TODO: Implementar verificação real de permissões quando conectar com backend
    return true;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[NoticesPage] Inicializando página de avisos...');
    debugPrint('[NoticesPage] Status de funcionário: $_isFuncionario');
    _loadAvisos();
  }
    Future<void> _loadAvisos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      debugPrint('[NoticesPage] Iniciando carregamento de avisos...');
      final avisosService = Provider.of<AvisosService>(context, listen: false);
      
      // Teste de conectividade primeiro
      debugPrint('[NoticesPage] Testando conectividade...');
      
      final avisos = await avisosService.getAvisos();
      
      setState(() {
        _avisos = avisos;
        _notices = avisos.map((aviso) => Notice.fromAviso(aviso)).toList();
        _isLoading = false;
      });
      
      debugPrint('[NoticesPage] Avisos carregados: ${avisos.length}');
      for (var aviso in avisos) {
        debugPrint('[NoticesPage] - Aviso ID ${aviso.id}: ${aviso.titulo}');
      }
    } catch (e, stackTrace) {
      debugPrint('[NoticesPage] Erro ao carregar avisos: $e');
      debugPrint('[NoticesPage] Stack trace: $stackTrace');
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
        SnackBar(content: Text('Erro na sincronização: ${e.toString().substring(0, min(50, e.toString().length))}')),
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
  }  @override
  Widget build(BuildContext context) {
    // Debug: Verificar status
    debugPrint('[NoticesPage] Build - isFuncionario: $_isFuncionario, isLoading: $_isLoading, avisos: ${_avisos.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Avisos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
            tooltip: 'Atualizar avisos',
          ),
          // Debug: Mostrar status de funcionário
          IconButton(
            icon: Icon(_isFuncionario ? Icons.admin_panel_settings : Icons.person),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Admin: $_isFuncionario')),
              );
            },
            tooltip: 'Status: ${_isFuncionario ? "Admin" : "Usuário"}',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _notices.isEmpty
                  ? _buildEmptyState()
                  : _buildNoticesList(),      floatingActionButton: _isFuncionario
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
                        mainAxisAlignment: MainAxisAlignment.end,                        children: [
                          _isFuncionario
                              ? TextButton(
                                  onPressed: () => _showEditNoticeDialog(context, notice),
                                  child: Text('Editar'),
                                )
                              : Container(),
                          _isFuncionario
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
      ),
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
          ),          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final avisosService = Provider.of<AvisosService>(context, listen: false);
                final success = await avisosService.deleteAviso(id);
                
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Aviso excluído com sucesso')),
                    );
                  }
                  
                  // Recarregar a lista
                  _loadAvisos();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir aviso')),
                    );
                  }
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir aviso: ${e.toString().substring(0, min(50, e.toString().length))}')),
                  );
                }
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
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
    bool _isSaving = false;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Novo Aviso'),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (titleController.text.isEmpty || contentController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Preencha todos os campos')),
                      );
                      return;
                    }
                    
                    setState(() {
                      _isSaving = true;
                    });
                      try {
                      // Usar ID temporário negativo para identificar avisos novos locais
                      final mockAuth = MockAuthService();
                      final newAviso = Aviso(
                        id: -DateTime.now().millisecondsSinceEpoch,
                        titulo: titleController.text,
                        mensagem: contentController.text,
                        dataPublicacao: DateTime.now(),
                        autorId: mockAuth.currentUserId, // Usar ID do MockAuthService
                        imagemUrl: null,
                      );
                        final avisosService = Provider.of<AvisosService>(context, listen: false);
                      await avisosService.createAviso(newAviso);
                      
                      Navigator.pop(dialogContext);
                      
                      // Atualizar a lista de avisos
                      _refreshNotices();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Aviso criado com sucesso!')),
                      );
                    } catch (e) {
                      setState(() {
                        _isSaving = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao criar aviso: ${e.toString().substring(0, min(50, e.toString().length))}')),
                      );
                    }
                  },
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Salvar'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  void _showEditNoticeDialog(BuildContext context, Notice notice) {
    final titleController = TextEditingController(text: notice.title);
    final contentController = TextEditingController(text: notice.content);
    bool _isSaving = false;
    
    // Encontrar o aviso original
    final avisoIndex = _avisos.indexWhere((aviso) => aviso.id == notice.id);
    final aviso = avisoIndex >= 0 ? _avisos[avisoIndex] : null;
    
    if (aviso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao encontrar aviso para edição')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (titleController.text.isEmpty || contentController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Preencha todos os campos')),
                      );
                      return;
                    }
                    
                    setState(() {
                      _isSaving = true;
                    });
                      try {
                      // Atualizar aviso
                      final updatedAviso = Aviso(
                        id: aviso.id,
                        titulo: titleController.text,
                        mensagem: contentController.text,
                        dataPublicacao: aviso.dataPublicacao,
                        autorId: aviso.autorId,
                        imagemUrl: aviso.imagemUrl,
                      );
                      
                      final avisosService = Provider.of<AvisosService>(context, listen: false);
                      await avisosService.updateAviso(updatedAviso);
                      
                      Navigator.pop(dialogContext);
                      
                      // Atualizar a lista de avisos
                      _refreshNotices();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Aviso atualizado com sucesso!')),
                      );
                    } catch (e) {
                      setState(() {
                        _isSaving = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao atualizar aviso: ${e.toString().substring(0, min(50, e.toString().length))}')),
                      );
                    }
                  },
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Salvar'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  // Helper para min Int
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
