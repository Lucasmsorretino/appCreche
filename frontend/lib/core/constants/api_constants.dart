class ApiConstants {
  // Configuração baseada na plataforma
  static const String baseUrl = 'http://localhost:8000'; // Para web/desktop
  // Use 'http://10.0.2.2:8000' para emulador Android
  // Use 'http://localhost:8000' para iOS simulator e web
  
  // API endpoints
  static const String login = '/token';
  static const String avisos = '/avisos';
  static const String rotinas = '/rotinas';
  static const String saude = '/saude';
  static const String calendario = '/calendario';
  static const String users = '/users';
  
  // Tempo limite das requisições (em segundos)
  static const int timeout = 15;
  
  // Endpoint para verificar saúde do backend
  static const String health = '/health';
}