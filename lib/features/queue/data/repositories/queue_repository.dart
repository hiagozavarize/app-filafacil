import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/queue_ticket.dart';

/// Contrato de repositório para gestão da fila de atendimento e histórico da UBS.
abstract interface class IQueueRepository {
  Future<List<QueueTicket>> getQueueTickets({String? ubsName});

  Future<QueueTicket> createTicket(QueueTicket ticket);

  Future<QueueTicket> updateTicketStatus({
    required String ticketId,
    required QueueStatus newStatus,
  });
}

/// Implementação remota conectada à API REST e Banco de Dados.
class RemoteQueueRepository implements IQueueRepository {
  const RemoteQueueRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<QueueTicket>> getQueueTickets({String? ubsName}) async {
    final list = await _apiClient.getList(
      ApiEndpoints.queue,
      queryParameters: ubsName != null
          ? <String, dynamic>{'ubs': ubsName}
          : null,
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(QueueTicket.fromJson)
        .toList();
  }

  @override
  Future<QueueTicket> createTicket(QueueTicket ticket) async {
    final json = await _apiClient.post(
      ApiEndpoints.queue,
      data: ticket.toJson(),
    );
    return QueueTicket.fromJson(json);
  }

  @override
  Future<QueueTicket> updateTicketStatus({
    required String ticketId,
    required QueueStatus newStatus,
  }) async {
    final endpoint = switch (newStatus) {
      QueueStatus.inAttendance => ApiEndpoints.callPatient(ticketId),
      QueueStatus.completed => ApiEndpoints.completeAttendance(ticketId),
      QueueStatus.absent => ApiEndpoints.markAbsent(ticketId),
      QueueStatus.cancelled => ApiEndpoints.cancelTicket(ticketId),
      _ => ApiEndpoints.queueTicketById(ticketId),
    };
    final json = await _apiClient.patch(
      endpoint,
      data: <String, dynamic>{'status': newStatus.name},
    );
    return QueueTicket.fromJson(json);
  }
}

/// Implementação Mock pré-populada com os pacientes e registros exatos do Figma.
class MockQueueRepository implements IQueueRepository {
  final List<QueueTicket> _tickets = <QueueTicket>[
    const QueueTicket(
      id: 'q-01',
      positionNumber: 1,
      ticketCode: 'CG-011',
      protocol: '#2026-0895',
      patientName: 'Maria Aparecida Souza',
      cpf: '412.890.123-00',
      birthDate: '14/03/1958',
      age: 68,
      susCard: '898 0012 3456 7890',
      specialty: 'Clínico Geral',
      room: 'Sala 02',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '07:00',
      priorityLabel: 'Prioridade: Idoso 60+',
      triageNotes: 'Controle de PA e renovação de receita',
      status: QueueStatus.inAttendance,
      doctorName: 'Dr. Roberto',
    ),
    const QueueTicket(
      id: 'q-02',
      positionNumber: 2,
      ticketCode: 'CG-012',
      protocol: '#2026-0896',
      patientName: 'José Carlos Oliveira',
      cpf: '198.342.567-10',
      birthDate: '22/07/1984',
      age: 42,
      susCard: '898 0045 8821 1029',
      specialty: 'Clínico Geral',
      room: 'Sala 02',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '07:30',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Avaliação clínica de rotina e exames laboratoriais',
      status: QueueStatus.next,
      doctorName: 'Dr. Roberto',
    ),
    const QueueTicket(
      id: 'q-03',
      positionNumber: 3,
      ticketCode: 'PD-004',
      protocol: '#2026-0897',
      patientName: 'Ana Beatriz Lima',
      cpf: '765.120.998-45',
      birthDate: '09/11/1996',
      age: 30,
      susCard: '898 0078 1290 4410',
      specialty: 'Pediatra',
      room: 'Sala 04',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '08:00',
      priorityLabel: 'Prioridade: Gestante / Criança',
      triageNotes: 'Acompanhamento pediátrico e carteira vacinal',
      status: QueueStatus.waiting,
      doctorName: 'Dra. Helena',
    ),
    const QueueTicket(
      id: 'q-04',
      positionNumber: 4,
      ticketCode: 'OD-008',
      protocol: '#2026-0898',
      patientName: 'Raimundo Nonato',
      cpf: '309.441.872-91',
      birthDate: '02/05/1975',
      age: 51,
      susCard: '898 0091 5532 0012',
      specialty: 'Dentista',
      room: 'Sala 01',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '08:30',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Avaliação odontológica preventiva',
      status: QueueStatus.waiting,
      doctorName: 'Dr. Marcos',
    ),
    // Registros históricos (Tela Histórico no Figma)
    const QueueTicket(
      id: 'h-01',
      positionNumber: 1,
      ticketCode: 'CG-001',
      protocol: '#2026-0891',
      patientName: 'Hiago Zavarize',
      cpf: '042.891.653-20',
      birthDate: '10/04/1999',
      age: 27,
      susCard: '704 8921 3301 0001',
      specialty: 'Clínico Geral',
      room: 'Sala 02',
      ubsName: 'UBS Central',
      scheduledDate: '16 Nov 2026',
      scheduledTime: '07:00',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Check-up anual concluído',
      status: QueueStatus.completed,
    ),
    const QueueTicket(
      id: 'h-02',
      positionNumber: 2,
      ticketCode: 'PD-002',
      protocol: '#2026-0890',
      patientName: 'Fernanda Costa Mendes',
      cpf: '519.220.418-33',
      birthDate: '18/08/1992',
      age: 34,
      susCard: '898 0031 9920 1122',
      specialty: 'Pediatra',
      room: 'Sala 04',
      ubsName: 'UBS Centro',
      scheduledDate: '16 Nov 2026',
      scheduledTime: '07:30',
      priorityLabel: 'Prioridade: Gestante / Criança',
      triageNotes: 'Puericultura concluída',
      status: QueueStatus.completed,
    ),
    const QueueTicket(
      id: 'h-03',
      positionNumber: 3,
      ticketCode: 'OD-003',
      protocol: '#2026-0889',
      patientName: 'Carlos Eduardo Rocha',
      cpf: '623.110.892-70',
      birthDate: '25/01/1988',
      age: 38,
      susCard: '898 0019 8827 3311',
      specialty: 'Dentista',
      room: 'Sala 01',
      ubsName: 'UBS Bacuri',
      scheduledDate: '16 Nov 2026',
      scheduledTime: '08:00',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Paciente não respondeu às 3 chamadas no painel',
      status: QueueStatus.absent,
    ),
    const QueueTicket(
      id: 'h-04',
      positionNumber: 4,
      ticketCode: 'GN-005',
      protocol: '#2026-0874',
      patientName: 'Juliana Alves Pereira',
      cpf: '812.540.319-12',
      birthDate: '12/09/1990',
      age: 36,
      susCard: '898 0065 4412 9087',
      specialty: 'Ginecologista',
      room: 'Sala 03',
      ubsName: 'UBS Santa Inês',
      scheduledDate: '15 Nov 2026',
      scheduledTime: '14:00',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Preventivo realizado',
      status: QueueStatus.completed,
    ),
    const QueueTicket(
      id: 'h-05',
      positionNumber: 5,
      ticketCode: 'CG-009',
      protocol: '#2026-0862',
      patientName: 'Antônio Marcos Santos',
      cpf: '201.987.654-88',
      birthDate: '05/06/1970',
      age: 56,
      susCard: '898 0054 3210 7654',
      specialty: 'Clínico Geral',
      room: 'Sala 02',
      ubsName: 'UBS Centro',
      scheduledDate: '15 Nov 2026',
      scheduledTime: '15:30',
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Cancelado a pedido do paciente',
      status: QueueStatus.cancelled,
    ),
  ];

  @override
  Future<List<QueueTicket>> getQueueTickets({String? ubsName}) async {
    return List<QueueTicket>.unmodifiable(_tickets);
  }

  @override
  Future<QueueTicket> createTicket(QueueTicket ticket) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _tickets.add(ticket);
    return ticket;
  }

  @override
  Future<QueueTicket> updateTicketStatus({
    required String ticketId,
    required QueueStatus newStatus,
  }) async {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) {
      throw StateError('Ticket $ticketId não encontrado.');
    }
    final updated = _tickets[index].copyWith(status: newStatus);
    _tickets[index] = updated;
    return updated;
  }
}

final queueRepositoryProvider = Provider<IQueueRepository>((ref) {
  if (EnvConfig.useMockBackend) {
    return MockQueueRepository();
  }
  return RemoteQueueRepository(ref.watch(apiClientProvider));
});

