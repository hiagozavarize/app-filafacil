/// Endpoints padronizados da API REST do FilaFácil UBS.
/// Prontos para integração com o backend e banco de dados.
final class ApiEndpoints {
  const ApiEndpoints._();

  // Autenticação & Perfil do Agente de Saúde
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/agents/me';

  // Unidades Básicas de Saúde (UBS) & Especialidades
  static const String ubsUnits = '/ubs';
  static const String specialties = '/specialties';
  static const String availableSlots = '/schedules/slots';

  // Operação da Fila de Atendimento
  static const String queue = '/queue';
  static String queueTicketById(String id) => '/queue/$id';
  static String callPatient(String id) => '/queue/$id/call';
  static String completeAttendance(String id) => '/queue/$id/complete';
  static String markAbsent(String id) => '/queue/$id/absent';
  static String cancelTicket(String id) => '/queue/$id/cancel';

  // Estatísticas e Histórico
  static const String statsOverview = '/stats/overview';
  static const String history = '/history';
}

