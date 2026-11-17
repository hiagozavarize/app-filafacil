import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/health_agent.dart';

class AuthState {
  const AuthState({
    required this.agent,
    this.isAuthenticated = true,
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

  Future<bool> login({required String cpf, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final agent = await _repository.login(cpf: cpf, password: password);
      state = AuthState(
        agent: agent,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String cpf,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final agent = await _repository.register(
        name: name,
        cpf: cpf,
        email: email,
        password: password,
      );
      state = AuthState(
        agent: agent,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile(HealthAgent updated) async {
    state = state.copyWith(isLoading: true);
    try {
      final saved = await _repository.updateProfile(updated);
      state = state.copyWith(agent: saved, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void changeActiveUbs(String ubsName) {
    state = state.copyWith(agent: state.agent.copyWith(assignedUbs: ubsName));
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
