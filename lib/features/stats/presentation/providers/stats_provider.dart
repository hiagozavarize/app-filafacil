import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/stats_repository.dart';
import '../../domain/entities/dashboard_stats.dart';

enum StatsPeriod {
  today('today', 'Hoje'),
  week('week', 'Últimos 7 dias'),
  month('month', 'Este mês');

  const StatsPeriod(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class StatsState {
  const StatsState({
    this.stats = const DashboardStats(),
    this.period = StatsPeriod.today,
    this.isLoading = false,
    this.isExporting = false,
    this.errorMessage,
  });

  final DashboardStats stats;
  final StatsPeriod period;
  final bool isLoading;
  final bool isExporting;
  final String? errorMessage;

  StatsState copyWith({
    DashboardStats? stats,
    StatsPeriod? period,
    bool? isLoading,
    bool? isExporting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatsState(
      stats: stats ?? this.stats,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StatsNotifier extends Notifier<StatsState> {
  @override
  StatsState build() => const StatsState();

  IStatsRepository get _repository => ref.read(statsRepositoryProvider);

  Future<void> loadStats({StatsPeriod? period}) async {
    final targetPeriod = period ?? state.period;
    state = state.copyWith(
      period: targetPeriod,
      isLoading: true,
      clearError: true,
    );
    try {
      final data = await _repository.getStats(period: targetPeriod.apiValue);
      state = state.copyWith(
        stats: data,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<String?> exportCsv() async {
    state = state.copyWith(isExporting: true, clearError: true);
    try {
      final csv = await _repository.exportReport(format: 'csv');
      state = state.copyWith(isExporting: false);
      return csv;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isExporting: false, errorMessage: msg);
      return null;
    }
  }
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(
  StatsNotifier.new,
);

