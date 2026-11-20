/// Configuração central de ambiente para conexão com a API REST do FilaFácil UBS.
///
/// Por padrão o aplicativo se conecta à API em produção no Render:
/// `https://backend-filafacil.onrender.com`
///
/// Para usar o modo offline (dados mockados) durante desenvolvimento:
/// `flutter run --dart-define=USE_MOCK_BACKEND=true`
///
/// Para apontar para um servidor local:
/// `flutter run --dart-define=API_BASE_URL=http://localhost:3001`
final class EnvConfig {
  const EnvConfig._();

  /// Define se o aplicativo utiliza os repositórios Mock em memória
  /// ou os repositórios remotos conectados à API REST em produção.
  static const bool useMockBackend = bool.fromEnvironment(
    'USE_MOCK_BACKEND',
    defaultValue: false,
  );

  /// URL base da API REST do FilaFácil UBS (sem barra final).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-filafacil.onrender.com',
  );

  /// URL para WebSocket (atualização em tempo real do painel da UBS).
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://backend-filafacil.onrender.com',
  );

  /// Timeout de conexão HTTP (dimensionado para suportar cold-start no Render).
  static const Duration connectTimeout = Duration(seconds: 45);

  /// Timeout de leitura HTTP (dimensionado para suportar cold-start no Render).
  static const Duration receiveTimeout = Duration(seconds: 45);

  /// Versão exibida no app.
  static const String appVersionLabel = 'SUS Digital • Versão 1.0';
}
