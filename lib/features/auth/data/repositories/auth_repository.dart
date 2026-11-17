import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/health_agent.dart';

/// Contrato de repositório de autenticação e perfil do Agente de Saúde.
abstract interface class IAuthRepository {
  Future<HealthAgent> login({required String cpf, required String password});

  Future<HealthAgent> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
  });

  Future<HealthAgent> getCurrentAgent();

  Future<HealthAgent> updateProfile(HealthAgent updatedAgent);

  Future<void> logout();
}

/// Implementação remota pronta para integração com a API REST e Banco de Dados.
class RemoteAuthRepository implements IAuthRepository {
  const RemoteAuthRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  @override
  Future<HealthAgent> login({
    required String cpf,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: <String, dynamic>{'cpf': cpf, 'password': password},
    );
    final token = response['access_token'] as String?;
    if (token != null) {
      await secureStorage.setAccessToken(token);
    }
    final agentJson =
        response['agent'] as Map<String, dynamic>? ?? response;
    return HealthAgent.fromJson(agentJson);
  }

  @override
  Future<HealthAgent> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: <String, dynamic>{
        'name': name,
        'cpf': cpf,
        'email': email,
        'password': password,
      },
    );
    final agentJson =
        response['agent'] as Map<String, dynamic>? ?? response;
    return HealthAgent.fromJson(agentJson);
  }

  @override
  Future<HealthAgent> getCurrentAgent() async {
    final response = await apiClient.get(ApiEndpoints.profile);
    return HealthAgent.fromJson(response);
  }

  @override
  Future<HealthAgent> updateProfile(HealthAgent updatedAgent) async {
    final response = await apiClient.put(
      ApiEndpoints.profile,
      data: updatedAgent.toJson(),
    );
    return HealthAgent.fromJson(response);
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } finally {
      await secureStorage.clearAuthSession();
    }
  }
}

/// Implementação Mock em memória pré-configurada com os dados do Figma.
class MockAuthRepository implements IAuthRepository {
  HealthAgent _currentAgent = HealthAgent.defaultMock;

  @override
  Future<HealthAgent> login({
    required String cpf,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (cpf.trim().isNotEmpty) {
      _currentAgent = _currentAgent.copyWith(cpf: cpf.trim());
    }
    return _currentAgent;
  }

  @override
  Future<HealthAgent> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _currentAgent = _currentAgent.copyWith(
      name: name.trim().isNotEmpty ? name.trim() : _currentAgent.name,
      cpf: cpf.trim().isNotEmpty ? cpf.trim() : _currentAgent.cpf,
      email: email.trim().isNotEmpty ? email.trim() : _currentAgent.email,
    );
    return _currentAgent;
  }

  @override
  Future<HealthAgent> getCurrentAgent() async {
    return _currentAgent;
  }

  @override
  Future<HealthAgent> updateProfile(HealthAgent updatedAgent) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentAgent = updatedAgent;
    return _currentAgent;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (EnvConfig.useMockBackend) {
    return MockAuthRepository();
  }
  return RemoteAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
