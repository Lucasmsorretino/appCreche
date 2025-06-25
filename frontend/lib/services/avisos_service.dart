import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../data/repositories/http_client.dart';
import '../models/aviso.dart';
import 'database_helper.dart';

abstract class AvisosService {
  Future<List<Aviso>> getAvisos();
  Future<Aviso?> getAviso(int id);
  Future<Aviso?> createAviso(Aviso aviso);
  Future<Aviso?> updateAviso(Aviso aviso);
  Future<bool> deleteAviso(int id);
  Future<bool> syncAvisos();
  Stream<bool> get syncStatusStream;
}

class RealAvisosService implements AvisosService {
  final HttpClient _httpClient;
  final DatabaseHelper _databaseHelper;
  final Connectivity _connectivity = Connectivity();
  static const String _logPrefix = '[AvisosService]';
  
  // Stream para notificar sobre status de sincronização
  final _syncController = StreamController<bool>.broadcast();
  bool _isSyncing = false;
  
  @override
  Stream<bool> get syncStatusStream => _syncController.stream;
  
  RealAvisosService(this._httpClient, this._databaseHelper);
  
  // Get all avisos - handles both online and offline
  @override
  Future<List<Aviso>> getAvisos() async {
    // Tentar obter do API primeiro
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final isAvailable = await _httpClient.isBackendAvailable();
        
        if (isAvailable) {
          debugPrint('$_logPrefix Buscando avisos da API');
          
          final response = await _httpClient.get(ApiConstants.avisos);
          final avisos = (response as List).map((json) => Aviso.fromJson(json)).toList();
          
          debugPrint('$_logPrefix Obtidos ${avisos.length} avisos da API');
          
          // Salvar todos no banco local, mesmo se offline depois
          for (var aviso in avisos) {
            await _databaseHelper.insertAviso(aviso);
          }
          
          return avisos;
        } else {
          debugPrint('$_logPrefix Backend indisponível, usando dados locais');
        }
      } else {
        debugPrint('$_logPrefix Sem conexão, usando dados locais');
      }
    } catch (e) {
      debugPrint('$_logPrefix Erro ao obter avisos da API: $e');
      // Continuar e obter do banco local
    }
    
    // Obter do banco local
    debugPrint('$_logPrefix Obtendo avisos do banco local');
    final localAvisos = await _databaseHelper.getAvisos();
    debugPrint('$_logPrefix Obtidos ${localAvisos.length} avisos do banco local');
    return localAvisos;
  }
  
  // Get a single aviso - handles both online and offline
  @override
  Future<Aviso?> getAviso(int id) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    // If offline, return from local database
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('$_logPrefix Sem conexão, buscando aviso $id do banco local');
      return _databaseHelper.getAviso(id);
    }
    
    // If online, try to get from API and update local database
    try {
      final isAvailable = await _httpClient.isBackendAvailable();
      if (!isAvailable) {
        debugPrint('$_logPrefix Backend indisponível, usando banco local para aviso $id');
        return _databaseHelper.getAviso(id);
      }
      
      debugPrint('$_logPrefix Buscando aviso $id da API');
      final response = await _httpClient.get('${ApiConstants.avisos}/$id');
      final aviso = Aviso.fromJson(response);
      
      // Update local database
      debugPrint('$_logPrefix Atualizando aviso $id no banco local');
      await _databaseHelper.insertAviso(aviso);
      
      return aviso;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao buscar aviso $id da API: $e');
      // Fall back to local database
      return _databaseHelper.getAviso(id);
    }
  }
  
  // Create a new aviso - handles both online and offline
  @override
  Future<Aviso?> createAviso(Aviso aviso) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    // If offline, store locally with temporary ID and sync later
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('$_logPrefix Sem conexão, criando aviso offline');
      
      // Create a temporary negative ID to identify local-only records
      final tempAviso = Aviso(
        id: -DateTime.now().millisecondsSinceEpoch, // Temporary negative ID
        titulo: aviso.titulo,
        mensagem: aviso.mensagem,
        dataPublicacao: aviso.dataPublicacao,
        imagemUrl: aviso.imagemUrl,
        autorId: aviso.autorId,
      );
      
      debugPrint('$_logPrefix Salvando aviso offline com ID temporário: ${tempAviso.id}');
      await _databaseHelper.insertOfflineAviso(tempAviso);
      return tempAviso;
    }
    
    // Check if backend is available
    final isAvailable = await _httpClient.isBackendAvailable();
    if (!isAvailable) {
      debugPrint('$_logPrefix Backend indisponível, criando aviso offline');
      final tempAviso = Aviso(
        id: -DateTime.now().millisecondsSinceEpoch,
        titulo: aviso.titulo,
        mensagem: aviso.mensagem,
        dataPublicacao: aviso.dataPublicacao,
        imagemUrl: aviso.imagemUrl,
        autorId: aviso.autorId,
      );
      
      await _databaseHelper.insertOfflineAviso(tempAviso);
      return tempAviso;
    }
    
    // If online, send to API and update local database
    try {
      debugPrint('$_logPrefix Enviando novo aviso para API');
      final response = await _httpClient.post(ApiConstants.avisos, aviso.toJson());
      final createdAviso = Aviso.fromJson(response);
      
      debugPrint('$_logPrefix Aviso criado na API com ID: ${createdAviso.id}');
      
      // Update local database
      await _databaseHelper.insertAviso(createdAviso);
      
      return createdAviso;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao criar aviso na API: $e');
      // Store locally if API fails
      final tempAviso = Aviso(
        id: -DateTime.now().millisecondsSinceEpoch, // Temporary negative ID
        titulo: aviso.titulo,
        mensagem: aviso.mensagem,
        dataPublicacao: aviso.dataPublicacao,
        imagemUrl: aviso.imagemUrl,
        autorId: aviso.autorId,
      );
      
      debugPrint('$_logPrefix Salvando localmente após falha na API');
      await _databaseHelper.insertOfflineAviso(tempAviso);
      return tempAviso;
    }
  }
  
  // Update an existing aviso - handles both online and offline
  @override
  Future<Aviso?> updateAviso(Aviso aviso) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    // If offline, update locally and mark for sync
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('$_logPrefix Sem conexão, atualizando aviso ${aviso.id} localmente');
      await _databaseHelper.updateAviso(aviso);
      return aviso;
    }
    
    // Check if backend is available
    final isAvailable = await _httpClient.isBackendAvailable();
    if (!isAvailable) {
      debugPrint('$_logPrefix Backend indisponível, atualizando aviso ${aviso.id} localmente');
      await _databaseHelper.updateAviso(aviso);
      return aviso;
    }
    
    // If online, update API and local database
    try {
      debugPrint('$_logPrefix Enviando atualização de aviso ${aviso.id} para API');
      final response = await _httpClient.put(
        '${ApiConstants.avisos}/${aviso.id}', 
        aviso.toJson()
      );
      final updatedAviso = Aviso.fromJson(response);
      
      // Update local database
      debugPrint('$_logPrefix Atualizando aviso ${aviso.id} no banco local');
      await _databaseHelper.updateAviso(updatedAviso);
      await _databaseHelper.markAvisoSynced(updatedAviso.id);
      
      return updatedAviso;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao atualizar aviso ${aviso.id} na API: $e');
      // Update locally if API fails
      await _databaseHelper.updateAviso(aviso);
      return aviso;
    }
  }
  
  // Delete an aviso - handles both online and offline
  @override
  Future<bool> deleteAviso(int id) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    // If offline, delete locally
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('$_logPrefix Sem conexão, excluindo aviso $id localmente');
      await _databaseHelper.deleteAviso(id);
      return true;
    }
    
    // Check if backend is available
    final isAvailable = await _httpClient.isBackendAvailable();
    if (!isAvailable) {
      debugPrint('$_logPrefix Backend indisponível, excluindo aviso $id localmente');
      await _databaseHelper.deleteAviso(id);
      return true;
    }
    
    // If online, delete from API and local database
    try {
      debugPrint('$_logPrefix Excluindo aviso $id da API');
      await _httpClient.delete('${ApiConstants.avisos}/$id');
      debugPrint('$_logPrefix Aviso $id excluído da API com sucesso');
      
      // Also delete locally
      await _databaseHelper.deleteAviso(id);
      return true;
    } catch (e) {
      debugPrint('$_logPrefix Erro ao excluir aviso $id da API: $e');
      // Try deleting locally anyway
      await _databaseHelper.deleteAviso(id);
      return false;
    }
  }
  
  // Synchronize any unsynced avisos with the server
  @override
  Future<bool> syncAvisos() async {
    // Evitar sincronização simultânea
    if (_isSyncing) {
      debugPrint('$_logPrefix Sincronização já em andamento, ignorando chamada');
      return false;
    }
    
    _isSyncing = true;
    _syncController.add(true);
    
    try {
      // Verificar conectividade
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('$_logPrefix Sem conexão, sincronização adiada');
        _isSyncing = false;
        _syncController.add(false);
        return false;
      }
      
      // Verificar se backend está disponível
      try {
        final isAvailable = await _httpClient.isBackendAvailable();
        if (!isAvailable) {
          debugPrint('$_logPrefix Backend indisponível, sincronização adiada');
          _isSyncing = false;
          _syncController.add(false);
          return false;
        }
      } catch (e) {
        debugPrint('$_logPrefix Erro ao verificar disponibilidade do backend: $e');
        _isSyncing = false;
        _syncController.add(false);
        return false;
      }
      
      debugPrint('$_logPrefix Iniciando sincronização de avisos...');
      
      // Buscar avisos não sincronizados
      final unsyncedAvisos = await _databaseHelper.getUnsyncedAvisos();
      debugPrint('$_logPrefix Encontrados ${unsyncedAvisos.length} avisos não sincronizados');
      
      if (unsyncedAvisos.isEmpty) {
        debugPrint('$_logPrefix Nenhum aviso para sincronizar');
        _isSyncing = false;
        _syncController.add(false);
        return true; // Sucesso - nada para sincronizar
      }
      
      int successCount = 0;
      int failCount = 0;
      
      // Processar cada aviso não sincronizado
      for (final aviso in unsyncedAvisos) {
        try {
          // Se ID negativo, é criação pendente
          if (aviso.id < 0) {
            debugPrint('$_logPrefix Sincronizando criação de aviso: ${aviso.titulo}');
            
            // Remover ID negativo para backend gerar novo
            final avisoToCreate = {
              'titulo': aviso.titulo,
              'mensagem': aviso.mensagem,
              'data_publicacao': aviso.dataPublicacao.toIso8601String(),
              'imagem_url': aviso.imagemUrl,
              'autor_id': aviso.autorId,
            };
            
            // Enviar para API
            final response = await _httpClient.post(
              ApiConstants.avisos, 
              avisoToCreate
            ).timeout(Duration(seconds: ApiConstants.timeout));
            
            if (response != null) {
              // Aviso criado no servidor, salvar versão correta
              final createdAviso = Aviso.fromJson(response);
              debugPrint('$_logPrefix Aviso criado no servidor com ID: ${createdAviso.id}');
              
              // Remover versão com ID temporário
              final deleteResult = await _databaseHelper.deleteAviso(aviso.id);
              debugPrint('$_logPrefix Removido aviso temporário ${aviso.id}: $deleteResult');
              
              // Inserir versão com ID do servidor
              final insertResult = await _databaseHelper.insertAviso(createdAviso);
              debugPrint('$_logPrefix Inserido aviso do servidor: $insertResult');
              
              successCount++;
            } else {
              debugPrint('$_logPrefix Resposta nula ao criar aviso no servidor');
              failCount++;
            }
          } else {
            // É uma atualização pendente
            debugPrint('$_logPrefix Sincronizando atualização de aviso: ${aviso.id}');
            
            // Verificar se o aviso ainda existe no servidor
            try {
              await _httpClient.get('${ApiConstants.avisos}/${aviso.id}')
                .timeout(Duration(seconds: ApiConstants.timeout));
              
              // Se chegou aqui, o aviso existe e podemos atualizar
              await _httpClient.put(
                '${ApiConstants.avisos}/${aviso.id}', 
                aviso.toJson()
              ).timeout(Duration(seconds: ApiConstants.timeout));
              
              // Marcar como sincronizado
              await _databaseHelper.markAvisoSynced(aviso.id);
              debugPrint('$_logPrefix Atualização de aviso ${aviso.id} sincronizada');
              
              successCount++;
            } catch (e) {
              debugPrint('$_logPrefix Erro ao verificar existência do aviso ${aviso.id}: $e');
              // O aviso pode não existir mais no servidor, tentar criar um novo
              try {
                final avisoToCreate = {
                  'titulo': aviso.titulo,
                  'mensagem': aviso.mensagem,
                  'data_publicacao': aviso.dataPublicacao.toIso8601String(),
                  'imagem_url': aviso.imagemUrl,
                  'autor_id': aviso.autorId,
                };
                
                final response = await _httpClient.post(
                  ApiConstants.avisos, 
                  avisoToCreate
                ).timeout(Duration(seconds: ApiConstants.timeout));
                
                if (response != null) {
                  final createdAviso = Aviso.fromJson(response);
                  
                  // Remover versão antiga
                  await _databaseHelper.deleteAviso(aviso.id);
                  
                  // Inserir versão nova
                  await _databaseHelper.insertAviso(createdAviso);
                  
                  debugPrint('$_logPrefix Aviso recriado com novo ID: ${createdAviso.id}');
                  successCount++;
                } else {
                  failCount++;
                }
              } catch (e) {
                debugPrint('$_logPrefix Falha ao recriar aviso: $e');
                failCount++;
              }
            }
          }
        } catch (e) {
          debugPrint('$_logPrefix Erro ao sincronizar aviso ${aviso.id}: $e');
          failCount++;
        }
      }
      
      debugPrint('$_logPrefix Sincronização concluída. Sucessos: $successCount, Falhas: $failCount');
      
      _isSyncing = false;
      _syncController.add(false);
      return failCount == 0; // Sucesso apenas se não houver falhas
    } catch (e) {
      debugPrint('$_logPrefix Erro durante sincronização: $e');
      _isSyncing = false;
      _syncController.add(false);
      return false;
    }
  }
  
  // Método para limpar recursos na destruição do serviço
  void dispose() {
    _syncController.close();
  }
}

class MockAvisosService implements AvisosService {
  final _syncController = StreamController<bool>.broadcast();
  
  @override
  Stream<bool> get syncStatusStream => _syncController.stream;
  
  @override
  Future<List<Aviso>> getAvisos() async {
    // Return mock data for testing
    return [
      Aviso(
        id: 1,
        titulo: 'Reunião de Pais',
        mensagem: 'Reunião de pais e mestres acontecerá no dia 20/10 às 19h.',
        dataPublicacao: DateTime.now().subtract(const Duration(days: 2)),
        autorId: 1,
      ),
      Aviso(
        id: 2,
        titulo: 'Festa Junina',
        mensagem: 'Nossa festa junina será realizada no dia 15/06. Traga sua família!',
        dataPublicacao: DateTime.now().subtract(const Duration(days: 5)),
        autorId: 1,
      ),
      Aviso(
        id: 3,
        titulo: 'Cardápio da Semana',
        mensagem: 'O cardápio desta semana já está disponível na área de alimentação.',
        dataPublicacao: DateTime.now().subtract(const Duration(hours: 12)),
        autorId: 2,
      ),
    ];
  }
  
  @override
  Future<Aviso?> getAviso(int id) async {
    final avisos = await getAvisos();
    try {
      return avisos.firstWhere((aviso) => aviso.id == id);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<Aviso?> createAviso(Aviso aviso) async {
    // Just return the aviso as if it was created
    return aviso;
  }
  
  @override
  Future<Aviso?> updateAviso(Aviso aviso) async {
    // Mock implementation - just return the same aviso
    return aviso;
  }
  
  @override
  Future<bool> deleteAviso(int id) async {
    // Mock implementation - pretend deletion was successful
    return true;
  }
  
  @override
  Future<bool> syncAvisos() async {
    // Mock implementation - pretend sync was successful
    _syncController.add(true);
    await Future.delayed(const Duration(seconds: 1));
    _syncController.add(false);
    return true;
  }
  
  void dispose() {
    _syncController.close();
  }
}