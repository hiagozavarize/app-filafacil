/// Hierarquia selada de exceções da aplicação para tratamento padronizado
/// entre camadas de Dados (API / Banco de Dados) e Apresentação.
sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Object? details;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Sem conexão com o servidor. Verifique sua internet.',
    super.statusCode,
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Sessão expirada ou credenciais inválidas.',
    super.statusCode = 401,
    super.code = 'UNAUTHORIZED',
    super.details,
  });
}

final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 422,
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

final class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Registro não encontrado no servidor.',
    super.statusCode = 404,
    super.code = 'NOT_FOUND',
    super.details,
  });
}

final class ServerException extends AppException {
  const ServerException({
    super.message = 'Erro interno no servidor da UBS. Tente novamente.',
    super.statusCode = 500,
    super.code = 'SERVER_ERROR',
    super.details,
  });
}
