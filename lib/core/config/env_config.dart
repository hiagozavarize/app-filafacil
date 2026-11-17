/// Configuração central de ambiente para conexão futura com API REST e Banco de Dados.
///
/// Para apontar para a API em produção/homologação, execute:
/// `flutter run --dart-define=USE_MOCK_BACKEND=false --dart-define=API_BASE_URL=https://api.filafacil.saude.gov.br/v1`
final class EnvConfig {
  const EnvConfig._();

  /// Define se o aplicativo utiliza os repositórios Mock (pré-populados)
  /// ou os repositórios remotos conectados à API/Banco de Dados.
  static const bool useMockBackend = bool.fromEnvironment(
    'USE_MOCK_BACKEND',
    defaultValue: true,
  );

  /// URL base da API REST do FilaFácil UBS.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// URL opcional para WebSocket / SSE (atualização em tempo real do painel da UBS).
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  /// Timeout de conexão HTTP em milissegundos.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Timeout de leitura HTTP em milissegundos.
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Versão exibida na Splash Screen.
  static const String appVersionLabel = 'SUS Digital • Versão 1.0';
}
