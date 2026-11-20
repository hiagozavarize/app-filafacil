/// Endpoints oficiais da API REST do FilaFácil UBS (`https://backend-filafacil.onrender.com/docs/`).
final class ApiEndpoints {
  const ApiEndpoints._();

  // Sistema
  static const String status = '/';
  static const String health = '/health';

  // Autenticação
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // Usuários & Perfil
  static const String profile = '/api/users/profile';
  static const String changePassword = '/api/users/change-password';

  // Pacientes (CADSUS)
  static const String patients = '/api/patients';
  static const String patientsSearch = '/api/patients/search';

  // Fila & Senhas
  static const String tickets = '/api/tickets';
  static const String ticketsWaiting = '/api/tickets/waiting';
  static const String callNextTicket = '/api/tickets/call-next';
  static String callTicket(String id) => '/api/tickets/$id/call';
  static String recallTicket(String id) => '/api/tickets/$id/recall';
  static String startTicket(String id) => '/api/tickets/$id/start';
  static String finishTicket(String id) => '/api/tickets/$id/finish';
  static String absentTicket(String id) => '/api/tickets/$id/absent';
  static const String exportTickets = '/api/tickets/export';

  // Salas & Consultórios
  static const String rooms = '/api/rooms';

  // Painel TV
  static const String tvCurrentCall = '/api/tv/current-call';
  static const String tvUpcoming = '/api/tv/upcoming';

  // Métricas & Relatórios
  static const String statsDashboard = '/api/stats/dashboard';
  static const String statsReports = '/api/stats/reports';
  static const String statsExport = '/api/stats/export';

  // Histórico & Auditoria
  static const String history = '/api/history';
  static String historyById(String id) => '/api/history/$id';
  static const String historyExport = '/api/history/export';
}
