import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/env_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage_service.dart';

/// Cliente HTTP centralizado (Dio) configurado com autenticação Bearer JWT,
/// logs estruturados e tratamento padronizado de respostas e erros da API FilaFácil UBS.
class ApiClient {
  ApiClient({
    required Dio dio,
    required SecureStorageService secureStorage,
    Logger? logger,
  }) : _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0)) {
    _dio = dio;
    _secureStorage = secureStorage;
    _configureInterceptors();
  }

  late final Dio _dio;
  late final SecureStorageService _secureStorage;
  final Logger _logger;

  void _configureInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = options.responseType == ResponseType.plain
              ? '*/*'
              : 'application/json';
          if (options.data != null) {
            options.headers['Content-Type'] = 'application/json';
          }
          _logger.d('[API REQ] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            '[API RES] ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          _logger.e(
            '[API ERR] ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}',
          );
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login')) {
            await _secureStorage.clearAuthSession();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: _cleanQuery(queryParameters),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>?> getNullable(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: _cleanQuery(queryParameters),
      );
      if (response.data == null) return null;
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        return map.isEmpty ? null : map;
      }
      return null;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: _cleanQuery(queryParameters),
      );
      return _asList(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<String> getText(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<String>(
        path,
        queryParameters: _cleanQuery(queryParameters),
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put<dynamic>(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<void>(path);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Map<String, dynamic>? _cleanQuery(Map<String, dynamic>? params) {
    if (params == null) return null;
    final cleaned = <String, dynamic>{};
    for (final entry in params.entries) {
      final v = entry.value;
      if (v != null && (v is! String || v.trim().isNotEmpty)) {
        cleaned[entry.key] = v;
      }
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      const candidateKeys = <String>[
        'data',
        'items',
        'tickets',
        'patients',
        'rooms',
        'history',
        'records',
        'results',
      ];
      for (final key in candidateKeys) {
        final value = map[key];
        if (value is List<dynamic>) return value;
      }
    }
    return <dynamic>[];
  }

  AppException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['error'] as String? ?? data['message'] as String?;
    } else if (data is String && data.trim().isNotEmpty) {
      serverMessage = data.trim();
    }

    // Simplifica mensagens técnicas longas do Prisma/banco de dados para exibição ao usuário.
    if (serverMessage != null &&
        (serverMessage.contains('Can\'t reach database server') ||
            serverMessage.contains('Invalid `prisma.'))) {
      serverMessage =
          'Serviço temporariamente indisponível: o servidor não conseguiu conectar ao banco de dados.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException(
        message:
            'Não foi possível conectar à API FilaFácil UBS. Verifique sua internet ou tente novamente em instantes.',
      );
    }

    return switch (statusCode) {
      401 => UnauthorizedException(
        message: serverMessage ?? 'Sessão expirada ou credenciais inválidas.',
      ),
      404 => NotFoundException(
        message: serverMessage ?? 'Recurso não encontrado.',
      ),
      400 || 409 || 422 => ValidationException(
        message: serverMessage ?? 'Dados inválidos enviados na requisição.',
        details: data,
      ),
      _ => ServerException(
        message: serverMessage ?? 'Erro inesperado na comunicação com a API.',
        statusCode: statusCode,
        details: data,
      ),
    };
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: EnvConfig.connectTimeout,
      receiveTimeout: EnvConfig.receiveTimeout,
    ),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: ref.watch(dioProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
