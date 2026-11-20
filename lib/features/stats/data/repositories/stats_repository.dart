import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/dashboard_stats.dart';

abstract interface class IStatsRepository {
  Future<DashboardStats> getStats({String period = 'today'});

  Future<String> exportReport({String format = 'csv'});
}

/// Implementação remota conectada a `/api/stats/dashboard`, `/api/stats/reports` e `/api/stats/export`.
class RemoteStatsRepository implements IStatsRepository {
  const RemoteStatsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DashboardStats> getStats({String period = 'today'}) async {
    final dashboardJson = await _apiClient.get(ApiEndpoints.statsDashboard);
    Map<String, dynamic>? reportJson;
    try {
      reportJson = await _apiClient.get(
        ApiEndpoints.statsReports,
        queryParameters: <String, dynamic>{'period': period},
      );
    } catch (_) {
      // Se /api/stats/reports falhar, mantém os dados do dashboard.
    }

    return DashboardStats.fromApi(
      dashboardJson: dashboardJson,
      reportJson: reportJson,
    );
  }

  @override
  Future<String> exportReport({String format = 'csv'}) async {
    return _apiClient.getText(
      ApiEndpoints.statsExport,
      queryParameters: <String, dynamic>{'format': format},
    );
  }
}

class MockStatsRepository implements IStatsRepository {
  @override
  Future<DashboardStats> getStats({String period = 'today'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return DashboardStats.mockDefault;
  }

  @override
  Future<String> exportReport({String format = 'csv'}) async {
    return 'periodo,atendidos,ausentes,espera_media_min\n$format,18,1,14.5';
  }
}

final statsRepositoryProvider = Provider<IStatsRepository>((ref) {
  if (EnvConfig.useMockBackend) {
    return MockStatsRepository();
  }
  return RemoteStatsRepository(ref.watch(apiClientProvider));
});

