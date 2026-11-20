import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/health_agent.dart';

class AuthState {
  const AuthState({
    required this.agent,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final HealthAgent agent;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    HealthAgent? agent,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      agent: agent ?? this.agent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState(agent: HealthAgent.defaultMock);
  }

  IAuthRepository get _repository => ref.read(authRepositoryProvider);

  String _formatError(Object error) {
    if (error is AppException) return error.message;
    return error.toString();
  }

  /// Tenta restaurar uma sessão JWT salva ao abrir o aplicativo.
  Future<bool> restoreSession() async {
    try {
      final hasToken = await _repository.hasSavedToken();
      if (!hasToken) return false;
      final agent = await _repository.getCurrentAgent();
      state = AuthState(
        agent: agent,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (_) {
      await _repository.logout();
      state = state.copyWith(isAuthenticated: false, isLoading: false);
      return false;
    }
  }

  Future<bool> login({
    required String login,
    required String password,
    bool rememberMe = true,
  }) async {
    if (login.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Informe seu CPF ou e-mail e sua senha.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final agent = await _repository.login(
        login: login,
        password: password,
        rememberMe: rememberMe,
      );
      state = AuthState(
        agent: agent,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
    String? phone,
    String? role,
    String? unitName,
    bool termsAccepted = true,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final agent = await _repository.register(
        name: name,
        cpf: cpf,
        email: email,
        password: password,
        phone: phone,
        role: role,
        unitName: unitName,
        termsAccepted: termsAccepted,
      );
      state = AuthState(
        agent: agent,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  Future<bool> forgotPassword({required String emailOrCpf}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.forgotPassword(emailOrCpf: emailOrCpf);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final agent = await _repository.getCurrentAgent();
      state = state.copyWith(agent: agent, isAuthenticated: true);
    } catch (_) {
      // Mantém estado atual em caso de falha transitória.
    }
  }

  Future<bool> updateProfile(HealthAgent updated) async {
    state = state.copyWith(isLoading: true);
    try {
      final saved = await _repository.updateProfile(updated);
      state = state.copyWith(agent: saved, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  void changeActiveUbs(String ubsName) {
    state = state.copyWith(agent: state.agent.copyWith(assignedUbs: ubsName));
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(
      agent: HealthAgent.defaultMock,
      isAuthenticated: false,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
