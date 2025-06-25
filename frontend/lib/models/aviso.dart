


class Aviso {
  final int id;
  final String titulo;
  final String mensagem;
  final DateTime dataPublicacao;
  final String? imagemUrl;
  final int autorId;
  
  Aviso({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.dataPublicacao,
    this.imagemUrl,
    required this.autorId,
  });
  
  factory Aviso.fromJson(Map<String, dynamic> json) {
    return Aviso(
      id: json['id'],
      titulo: json['title'],  // Backend usa 'title'
      mensagem: json['content'],  // Backend usa 'content'  
      dataPublicacao: DateTime.parse(json['created_at']),  // Backend usa 'created_at'
      imagemUrl: json['target_classroom'],  // Usando este campo temporariamente
      autorId: json['author_id'],  // Backend usa 'author_id'
    );  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': titulo,  // Backend espera 'title'
      'content': mensagem,  // Backend espera 'content'
      'created_at': dataPublicacao.toIso8601String(),  // Backend usa 'created_at'
      'target_classroom': imagemUrl,  // Usando este campo temporariamente
      'author_id': autorId,  // Backend espera 'author_id'
    };
  }
}