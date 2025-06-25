import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/auth_service.dart';
import 'services/database_helper.dart';
import 'services/service_provider.dart';
import 'services/avisos_service.dart';
import 'services/login_service.dart';
import 'services/mock_auth_service.dart'; // Adicionado
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/routine_page.dart';
import 'pages/health_page.dart';
import 'pages/calendar_page.dart';
import 'pages/notices_page.dart';
import 'package:device_preview/device_preview.dart';
import 'data/repositories/http_client.dart';

void main() async {
  // Ensure Flutter is initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar suporte a SQLite para desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    debugPrint('[Main] Inicializando SQLite FFI para plataformas desktop');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Skip database initialization for web testing with DevicePreview
  if (!kIsWeb) {
    try {
      debugPrint('[Main] Iniciando configuração do banco de dados...');
      
      // Inicializar banco de dados
      final dbHelper = DatabaseHelper();
      
      // Tentar resetar o banco de dados para resolver problemas persistentes
      await dbHelper.resetDatabase();
      debugPrint('[Main] Banco de dados resetado para resolver possíveis problemas');
      
      // Obter instância do banco
      final db = await dbHelper.database;
      
      if (db == null) {
        debugPrint('[Main] ERRO CRÍTICO: Falha na inicialização do banco de dados!');
      } else {
        debugPrint('[Main] Banco de dados inicializado com sucesso');
        
        // Verificar funcionamento do banco
        final isWorking = await dbHelper.isDatabaseWorking();
        debugPrint('[Main] Teste de funcionamento do banco: ${isWorking ? "OK" : "FALHA"}');
        
        if (!isWorking) {
          debugPrint('[Main] Tentando recriar o banco de dados...');
          await dbHelper.resetDatabase();
          final isWorkingAfterReset = await dbHelper.isDatabaseWorking();
          debugPrint('[Main] Teste após recriação: ${isWorkingAfterReset ? "OK" : "FALHA PERSISTENTE"}');
        }
        
        // Inserir dados de teste para desenvolvimento
        await dbHelper.insertTestData();
        
        // Verificar quantidade de dados no banco após inserção
        final avisos = await dbHelper.getAvisos();
        debugPrint('[Main] Avisos no banco após inicialização: ${avisos.length}');
        
        // Imprimir os IDs dos avisos para verificação
        if (avisos.isNotEmpty) {
          debugPrint('[Main] IDs dos avisos no banco: ${avisos.map((a) => a.id).toList()}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[Main] Erro crítico durante inicialização do banco: $e');
      debugPrint('[Main] Stack trace: $stackTrace');
    }
  }
  
  // Setup service locator with test mode flag
  setupServiceLocator(isTestMode: kIsWeb);
  
  // Inicializar MockAuthService para desenvolvimento
  if (kDebugMode) {
    final mockAuth = MockAuthService();
    await mockAuth.initialize();
    debugPrint('[Main] MockAuthService inicializado para desenvolvimento');
  }
  
  // Verificar disponibilidade do backend (em background para não bloquear inicialização)
  Future.delayed(const Duration(milliseconds: 500), () async {
    if (!kIsWeb) {
      try {
        final httpClient = serviceLocator<HttpClient>();
        final isAvailable = await httpClient.isBackendAvailable();
        debugPrint('[Main] Backend disponível: $isAvailable');
        
        // Tentativa de sincronização inicial se backend estiver disponível
        if (isAvailable) {
          final avisosService = serviceLocator<AvisosService>();
          final syncResult = await avisosService.syncAvisos();
          debugPrint('[Main] Sincronização inicial: ${syncResult ? "Sucesso" : "Falha"}');
        }
      } catch (e) {
        debugPrint('[Main] Erro ao verificar backend: $e');
      }
    }
  });
  
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Desativar em produção
      builder: (context) => CmeiApp(),
    ),
  );
}

class CmeiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Get your service instances from the service locator
        ChangeNotifierProvider(
          create: (context) => serviceLocator<AuthService>(),
        ),
        // Add other providers as needed
        Provider(
          create: (context) => serviceLocator<AvisosService>(),
        ),
        Provider(
          create: (context) => serviceLocator<LoginService>(),
        ),
        // You can add more providers here
      ],
      child: MaterialApp(
        title: 'CMEI App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginPage(),
          '/home': (context) => HomePage(),
          '/routine': (context) => RoutinePage(),
          '/health': (context) => SaudePage(),
          '/calendar': (context) => CalendarioPage(),
          '/notices': (context) => NoticesPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
