import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/health_agent.dart';

/// Contrato de repositório de autenticação e perfil do operador da UBS.
abstract interface class IAuthRepository {
  Future<HealthAgent> login({
    required String login,
    required String password,
    bool rememberMe = true,
  });

  Future<HealthAgent> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
    String? phone,
    String? role,
    String? cns,
    String? unitName,
    String? registration,
    bool termsAccepted = true,
  });

  Future<void> forgotPassword({required String emailOrCpf});

  Future<bool> hasSavedToken();

  Future<HealthAgent> getCurrentAgent();

  Future<HealthAgent> updateProfile(HealthAgent updatedAgent);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
}

/// Implementação remota conectada à API REST `https://backend-filafacil.onrender.com`.
class RemoteAuthRepository implements IAuthRepository {
  const RemoteAuthRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  @override
  Future<HealthAgent> login({
    required String login,
    required String password,
    bool rememberMe = true,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: <String, dynamic>{
        'login': login.trim(),
        'password': password,
        'rememberMe': rememberMe,
      },
    );

    final token =
        response['token'] as String? ?? response['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      await secureStorage.setAccessToken(token);
    }

    final userJson =
        response['user'] as Map<String, dynamic>? ??
        response['agent'] as Map<String, dynamic>? ??
        response;
    final agent = HealthAgent.fromJson(userJson);
    await secureStorage.setActiveUbs(agent.assignedUbs);
    return agent;
  }

  @override
  Future<HealthAgent> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
    String? phone,
    String? role,
    String? cns,
    String? unitName,
    String? registration,
    bool termsAccepted = true,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'cpf': cpf.trim(),
      'password': password,
      'termsAccepted': termsAccepted,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      if (cns != null && cns.trim().isNotEmpty) 'cns': cns.trim(),
      if (unitName != null && unitName.trim().isNotEmpty)
        'unitName': unitName.trim(),
      if (registration != null && registration.trim().isNotEmpty)
        'registration': registration.trim(),
    };

    final response = await apiClient.post(ApiEndpoints.register, data: payload);

    final token =
        response['token'] as String? ?? response['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      await secureStorage.setAccessToken(token);
      final userJson =
          response['user'] as Map<String, dynamic>? ??
          response['agent'] as Map<String, dynamic>? ??
          response;
      final agent = HealthAgent.fromJson(userJson);
      await secureStorage.setActiveUbs(agent.assignedUbs);
      return agent;
    }

    // Caso o endpoint de registro retorne apenas o usuário sem JWT,
    // realiza login automático para obter o Bearer Token.
    try {
      return await login(login: email.trim(), password: password);
    } catch (_) {
      final userJson =
          response['user'] as Map<String, dynamic>? ??
          response['agent'] as Map<String, dynamic>? ??
          response;
      return HealthAgent.fromJson(userJson);
    }
  }

  @override
  Future<void> forgotPassword({required String emailOrCpf}) async {
    await apiClient.post(
      ApiEndpoints.forgotPassword,
      data: <String, dynamic>{'emailOrCpf': emailOrCpf.trim()},
    );
  }

  @override
  Future<bool> hasSavedToken() async {
    final token = await secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<HealthAgent> getCurrentAgent() async {
    final response = await apiClient.get(ApiEndpoints.profile);
    final userJson =
        response['user'] as Map<String, dynamic>? ??
        response['agent'] as Map<String, dynamic>? ??
        response;
    return HealthAgent.fromJson(userJson);
  }

  @override
  Future<HealthAgent> updateProfile(HealthAgent updatedAgent) async {
    final response = await apiClient.put(
      ApiEndpoints.profile,
      data: updatedAgent.toProfileUpdateJson(),
    );
    final userJson =
        response['user'] as Map<String, dynamic>? ??
        response['agent'] as Map<String, dynamic>? ??
        response;
    final saved = HealthAgent.fromJson(userJson);
    await secureStorage.setActiveUbs(saved.assignedUbs);
    return saved;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.put(
      ApiEndpoints.changePassword,
      data: <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<void> logout() async {
    await secureStorage.clearAuthSession();
  }
}

/// Implementação Mock em memória (usada em testes e quando `USE_MOCK_BACKEND=true`).
class MockAuthRepository implements IAuthRepository {
  HealthAgent _currentAgent = HealthAgent.defaultMock;

  @override
  Future<HealthAgent> login({
    required String login,
    required String password,
    bool rememberMe = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final trimmed = login.trim();
    if (trimmed.isNotEmpty) {
      if (trimmed.contains('@')) {
        _currentAgent = _currentAgent.copyWith(email: trimmed);
      } else {
        _currentAgent = _currentAgent.copyWith(cpf: trimmed);
      }
    }
    return _currentAgent;
  }

  @override
  Future<HealthAgent> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
    String? phone,
    String? role,
    String? cns,
    String? unitName,
    String? registration,
    bool termsAccepted = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _currentAgent = _currentAgent.copyWith(
      name: name.trim().isNotEmpty ? name.trim() : _currentAgent.name,
      cpf: cpf.trim().isNotEmpty ? cpf.trim() : _currentAgent.cpf,
      email: email.trim().isNotEmpty ? email.trim() : _currentAgent.email,
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      role: role?.trim().isNotEmpty == true ? role!.trim() : null,
      cns: cns?.trim().isNotEmpty == true ? cns!.trim() : null,
      assignedUbs:
          unitName?.trim().isNotEmpty == true ? unitName!.trim() : null,
      registration:
          registration?.trim().isNotEmpty == true ? registration!.trim() : null,
    );
    return _currentAgent;
  }

  @override
  Future<void> forgotPassword({required String emailOrCpf}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<bool> hasSavedToken() async => false;

  @override
  Future<HealthAgent> getCurrentAgent() async => _currentAgent;

  @override
  Future<HealthAgent> updateProfile(HealthAgent updatedAgent) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentAgent = updatedAgent;
    return _currentAgent;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
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
