import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import '../data/repositories/http_client.dart';
import '../data/repositories/auth_repository.dart';
import 'avisos_service.dart';
import 'auth_service.dart';
import 'database_helper.dart';
import 'login_service.dart';
import 'rotina_service.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator({bool isTestMode = false}) {
  // Register core services
  serviceLocator.registerLazySingleton(() => HttpClient());
  serviceLocator.registerLazySingleton(() => DatabaseHelper());
  
  // Register repositories
  serviceLocator.registerLazySingleton(
    () => AuthRepository(serviceLocator<HttpClient>())
  );
  
  // Register business services
  serviceLocator.registerLazySingleton<AvisosService>(
    () => RealAvisosService(
      serviceLocator<HttpClient>(),
      serviceLocator<DatabaseHelper>(),
    ),
  );
  
  serviceLocator.registerLazySingleton(
    () => AuthService(serviceLocator<AuthRepository>())
  );
  
  serviceLocator.registerLazySingleton(
    () => LoginService(serviceLocator<HttpClient>())
  );
  
  serviceLocator.registerLazySingleton(
    () => RotinaService(
      serviceLocator<HttpClient>(),
      serviceLocator<DatabaseHelper>()
    )
  );
}