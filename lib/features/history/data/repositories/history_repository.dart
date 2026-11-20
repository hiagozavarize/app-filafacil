import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../queue/domain/entities/queue_ticket.dart';

abstract interface class IHistoryRepository {
  Future<List<QueueTicket>> getHistory({
    String? startDate,
    String? endDate,
    String? status,
    String? specialty,
    String? search,
  });

  Future<QueueTicket> getHistoryAuditById(String id);

  Future<String> exportHistoryCsv();
}

/// Implementação remota conectada a `/api/history`, `/api/history/{id}` e `/api/history/export`.
class RemoteHistoryRepository implements IHistoryRepository {
  const RemoteHistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<QueueTicket>> getHistory({
    String? startDate,
    String? endDate,
    String? status,
    String? specialty,
    String? search,
  }) async {
    final list = await _apiClient.getList(
      ApiEndpoints.history,
      queryParameters: <String, dynamic>{
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'specialty': specialty,
        'search': search,
      },
    );
    var pos = 1;
    return list.whereType<Map<String, dynamic>>().map((item) {
      return QueueTicket.fromJson(item, fallbackPosition: pos++);
    }).toList();
  }

  @override
  Future<QueueTicket> getHistoryAuditById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.historyById(id));
    final nested =
        response['ticket'] as Map<String, dynamic>? ??
        response['data'] as Map<String, dynamic>? ??
        response;
    return QueueTicket.fromJson(nested);
  }

  @override
  Future<String> exportHistoryCsv() async {
    return _apiClient.getText(ApiEndpoints.historyExport);
  }
}

class MockHistoryRepository implements IHistoryRepository {
  static const List<QueueTicket> _records = <QueueTicket>[
    QueueTicket(
      id: 'h-01',
      positionNumber: 1,
      ticketCode: 'NOR-001',
      protocol: '#NOR-001',
      patientName: 'Hiago Zavarize',
      cpf: '042.891.653-20',
      birthDate: '10/04/1999',
      age: 27,
      susCard: '704 8921 3301 0001',
      specialty: 'Clínica Geral',
      room: 'Consultorio 01',
      ubsName: 'UBS Centro',
      scheduledDate: '16 Nov 2026',
      scheduledTime: '07:00',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Check-up anual concluído',
      status: QueueStatus.completed,
      waitTimeMinutes: 12,
      serviceDurationMinutes: 16,
      cid10: 'Z00',
    ),
    QueueTicket(
      id: 'h-02',
      positionNumber: 2,
      ticketCode: 'PRE-002',
      protocol: '#PRE-002',
      patientName: 'Fernanda Costa Mendes',
      cpf: '519.220.418-33',
      birthDate: '18/08/1992',
      age: 34,
      susCard: '898 0031 9920 1122',
      specialty: 'Pediatria',
      room: 'Consultorio 04',
      ubsName: 'UBS Centro',
      scheduledDate: '16 Nov 2026',
      scheduledTime: '07:30',
      priorityLabel: 'Prioridade: Gestante',
      priority: TicketPriority.gestante,
      triageNotes: 'Puericultura concluída',
      status: QueueStatus.completed,
      waitTimeMinutes: 9,
      serviceDurationMinutes: 20,
    ),
    QueueTicket(
      id: 'h-03',
      positionNumber: 3,
      ticketCode: 'NOR-003',
      protocol: '#NOR-003',
      patientName: 'Carlos Eduardo Rocha',
      cpf: '623.110.892-70',
      birthDate: '25/01/1988',
      age: 38,
      susCard: '898 0019 8827 3311',
      specialty: 'Odontologia',
      room: 'Consultorio 02',
      ubsName: 'UBS Bacuri',
      scheduledDate: '16 Nov 2026',
      scheduledTime: '08:00',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Paciente não respondeu às 3 chamadas no painel',
      status: QueueStatus.absent,
    ),
  ];

  @override
  Future<List<QueueTicket>> getHistory({
    String? startDate,
    String? endDate,
    String? status,
    String? specialty,
    String? search,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final q = (search ?? '').trim().toLowerCase();
    return _records.where((r) {
      final matchStatus =
          status == null || status.isEmpty || r.status.apiValue == status;
      final matchSearch =
          q.isEmpty ||
          r.patientName.toLowerCase().contains(q) ||
          r.cpf.toLowerCase().contains(q) ||
          r.ticketCode.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  @override
  Future<QueueTicket> getHistoryAuditById(String id) async {
    return _records.firstWhere(
      (r) => r.id == id,
      orElse: () => _records.first,
    );
  }

  @override
  Future<String> exportHistoryCsv() async {
    return 'codigo,paciente,status,especialidade\nNOR-001,Hiago Zavarize,FINISHED,Clínica Geral';
  }
}

final historyRepositoryProvider = Provider<IHistoryRepository>((ref) {
  if (EnvConfig.useMockBackend) {
    return MockHistoryRepository();
  }
  return RemoteHistoryRepository(ref.watch(apiClientProvider));
});

