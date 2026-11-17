import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/env_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage_service.dart';

/// Cliente HTTP centralizado (Dio) pré-configurado com interceptors de
/// autenticação JWT, logs estruturados e mapeamento de erros da API.
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
          options.headers['Accept'] = 'application/json';
          options.headers['Content-Type'] = 'application/json';
          _logger.d('[API REQ] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            '[API RES] ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            '[API ERR] ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}',
          );
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
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? <dynamic>[];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path, data: data);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(path, data: data);
      return response.data ?? <String, dynamic>{};
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

  AppException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final serverMessage = data is Map<String, dynamic>
        ? (data['message'] as String? ?? data['error'] as String?)
        : null;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    return switch (statusCode) {
      401 => UnauthorizedException(
        message: serverMessage ?? 'Sessão expirada ou credenciais inválidas.',
      ),
      404 => NotFoundException(
        message: serverMessage ?? 'Recurso não encontrado.',
      ),
      400 || 422 => ValidationException(
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
