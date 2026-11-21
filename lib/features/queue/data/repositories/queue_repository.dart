import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/queue_ticket.dart';
import '../../domain/entities/room.dart';

/// Contrato de repositório para gestão de fila, senhas, pacientes (CADSUS) e salas da UBS.
abstract interface class IQueueRepository {
  Future<List<QueueTicket>> getQueueTickets({
    String? status,
    String? specialty,
    String? roomId,
    String? search,
  });

  Future<List<QueueTicket>> getWaitingQueue();

  Future<QueueTicket> createTicket(QueueTicket ticket);

  Future<QueueTicket> callNextTicket({
    required String roomName,
    String? doctorName,
  });

  Future<QueueTicket> callTicket({
    required String ticketId,
    required String roomName,
    String? doctorName,
  });

  Future<QueueTicket> recallTicket(String ticketId);

  Future<QueueTicket> startAttendance(String ticketId);

  Future<QueueTicket> finishAttendance({
    required String ticketId,
    String? notes,
    String? cid10,
  });

  Future<QueueTicket> markAbsent(String ticketId);

  Future<List<Patient>> searchPatients(String query);

  Future<Patient> createPatient(Patient patient);

  Future<List<Room>> getRooms();

  Future<QueueTicket?> getTvCurrentCall();

  Future<List<QueueTicket>> getTvUpcoming();
}

/// Implementação remota conectada à API REST `https://backend-filafacil.onrender.com`.
class RemoteQueueRepository implements IQueueRepository {
  const RemoteQueueRepository(this._apiClient);

  final ApiClient _apiClient;

  QueueTicket _parseTicketResponse(
    Map<String, dynamic> response, {
    int? fallbackPosition,
  }) {
    final nested =
        response['ticket'] as Map<String, dynamic>? ??
        response['data'] as Map<String, dynamic>? ??
        response;
    return QueueTicket.fromJson(nested, fallbackPosition: fallbackPosition);
  }

  @override
  Future<List<QueueTicket>> getQueueTickets({
    String? status,
    String? specialty,
    String? roomId,
    String? search,
  }) async {
    final list = await _apiClient.getList(
      ApiEndpoints.tickets,
      queryParameters: <String, dynamic>{
        'status': status,
        'specialty': specialty,
        'roomId': roomId,
        'search': search,
      },
    );
    var pos = 1;
    return list.whereType<Map<String, dynamic>>().map((item) {
      return QueueTicket.fromJson(item, fallbackPosition: pos++);
    }).toList();
  }

  @override
  Future<List<QueueTicket>> getWaitingQueue() async {
    final list = await _apiClient.getList(ApiEndpoints.ticketsWaiting);
    var pos = 1;
    return list.whereType<Map<String, dynamic>>().map((item) {
      return QueueTicket.fromJson(item, fallbackPosition: pos++);
    }).toList();
  }

  @override
  Future<QueueTicket> createTicket(QueueTicket ticket) async {
    final response = await _apiClient.post(
      ApiEndpoints.tickets,
      data: ticket.toCreateTicketPayload(),
    );
    return _parseTicketResponse(response);
  }

  @override
  Future<QueueTicket> callNextTicket({
    required String roomName,
    String? doctorName,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.callNextTicket,
      data: <String, dynamic>{
        'roomName': roomName,
        if (doctorName != null && doctorName.trim().isNotEmpty) ...{
          'professionalName': doctorName.trim(),
          'doctorName': doctorName.trim(),
        },
      },
    );
    return _parseTicketResponse(response);
  }

  @override
  Future<QueueTicket> callTicket({
    required String ticketId,
    required String roomName,
    String? doctorName,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.callTicket(ticketId),
      data: <String, dynamic>{
        'roomName': roomName,
        if (doctorName != null && doctorName.trim().isNotEmpty) ...{
          'professionalName': doctorName.trim(),
          'doctorName': doctorName.trim(),
        },
      },
    );
    return _parseTicketResponse(response);
  }

  @override
  Future<QueueTicket> recallTicket(String ticketId) async {
    final response = await _apiClient.post(ApiEndpoints.recallTicket(ticketId));
    return _parseTicketResponse(response);
  }

  @override
  Future<QueueTicket> startAttendance(String ticketId) async {
    final response = await _apiClient.post(ApiEndpoints.startTicket(ticketId));
    return _parseTicketResponse(response);
  }

  @override
  Future<QueueTicket> finishAttendance({
    required String ticketId,
    String? notes,
    String? cid10,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.finishTicket(ticketId),
      data: <String, dynamic>{
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (cid10 != null && cid10.trim().isNotEmpty) ...{
          'cid': cid10.trim(),
          'cid10': cid10.trim(),
        },
      },
    );
    return _parseTicketResponse(response);
  }

  @override
  Future<QueueTicket> markAbsent(String ticketId) async {
    final response = await _apiClient.post(ApiEndpoints.absentTicket(ticketId));
    return _parseTicketResponse(response);
  }

  @override
  Future<List<Patient>> searchPatients(String query) async {
    if (query.trim().isEmpty) return const <Patient>[];
    final list = await _apiClient.getList(
      ApiEndpoints.patientsSearch,
      queryParameters: <String, dynamic>{'q': query.trim()},
    );
    return list.whereType<Map<String, dynamic>>().map(Patient.fromJson).toList();
  }

  @override
  Future<Patient> createPatient(Patient patient) async {
    final response = await _apiClient.post(
      ApiEndpoints.patients,
      data: patient.toCreateJson(),
    );
    final nested = response['patient'] as Map<String, dynamic>? ?? response;
    return Patient.fromJson(nested);
  }

  @override
  Future<List<Room>> getRooms() async {
    final list = await _apiClient.getList(ApiEndpoints.rooms);
    return list.whereType<Map<String, dynamic>>().map(Room.fromJson).toList();
  }

  @override
  Future<QueueTicket?> getTvCurrentCall() async {
    final response = await _apiClient.getNullable(ApiEndpoints.tvCurrentCall);
    if (response == null) return null;
    return _parseTicketResponse(response);
  }

  @override
  Future<List<QueueTicket>> getTvUpcoming() async {
    final list = await _apiClient.getList(ApiEndpoints.tvUpcoming);
    var pos = 1;
    return list.whereType<Map<String, dynamic>>().map((item) {
      return QueueTicket.fromJson(item, fallbackPosition: pos++);
    }).toList();
  }
}

/// Implementação Mock em memória (usada em testes e modo `--dart-define=USE_MOCK_BACKEND=true`).
class MockQueueRepository implements IQueueRepository {
  final List<QueueTicket> _tickets = <QueueTicket>[
    const QueueTicket(
      id: 'q-01',
      positionNumber: 1,
      ticketCode: 'PRE-001',
      protocol: '#PRE-001',
      patientName: 'Maria Aparecida Souza',
      cpf: '412.890.123-00',
      birthDate: '14/03/1958',
      age: 68,
      susCard: '898 0012 3456 7890',
      specialty: 'Clínica Geral',
      room: 'Consultorio 01',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '07:00',
      priorityLabel: 'Prioridade: Idoso 60+',
      priority: TicketPriority.preferencial60,
      triageNotes: 'Controle de PA e renovação de receita',
      status: QueueStatus.inAttendance,
      doctorName: 'Dra. Juliana Mendes',
    ),
    const QueueTicket(
      id: 'q-02',
      positionNumber: 2,
      ticketCode: 'NOR-002',
      protocol: '#NOR-002',
      patientName: 'José Carlos Oliveira',
      cpf: '198.342.567-10',
      birthDate: '22/07/1984',
      age: 42,
      susCard: '898 0045 8821 1029',
      specialty: 'Clínica Geral',
      room: 'Consultorio 01',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '07:30',
      priorityLabel: 'Atendimento Regular',
      priority: TicketPriority.normal,
      triageNotes: 'Avaliação clínica de rotina e exames laboratoriais',
      status: QueueStatus.next,
      doctorName: 'Dra. Juliana Mendes',
    ),
    const QueueTicket(
      id: 'q-03',
      positionNumber: 3,
      ticketCode: 'PRE-003',
      protocol: '#PRE-003',
      patientName: 'Ana Beatriz Lima',
      cpf: '765.120.998-45',
      birthDate: '09/11/1996',
      age: 30,
      susCard: '898 0078 1290 4410',
      specialty: 'Pediatria',
      room: 'Consultorio 04',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '08:00',
      priorityLabel: 'Prioridade: Gestante',
      priority: TicketPriority.gestante,
      triageNotes: 'Acompanhamento pediátrico e carteira vacinal',
      status: QueueStatus.waiting,
      doctorName: 'Dra. Helena',
    ),
    const QueueTicket(
      id: 'q-04',
      positionNumber: 4,
      ticketCode: 'NOR-004',
      protocol: '#NOR-004',
      patientName: 'Raimundo Nonato',
      cpf: '309.441.872-91',
      birthDate: '02/05/1975',
      age: 51,
      susCard: '898 0091 5532 0012',
      specialty: 'Odontologia',
      room: 'Consultorio 02',
      ubsName: 'UBS Centro',
      scheduledDate: '19 Nov 2026',
      scheduledTime: '08:30',
      priorityLabel: 'Atendimento Regular',
      priority: TicketPriority.normal,
      triageNotes: 'Avaliação odontológica preventiva',
      status: QueueStatus.waiting,
      doctorName: 'Dr. Marcos',
    ),
  ];

  final List<Room> _rooms = const <Room>[
    Room(
      id: 'r-01',
      name: 'Consultorio 01',
      specialty: 'Clínica Geral',
      status: 'DISPONIVEL',
      currentDoctor: 'Dra. Juliana Mendes',
    ),
    Room(
      id: 'r-02',
      name: 'Consultorio 02',
      specialty: 'Odontologia',
      status: 'DISPONIVEL',
      currentDoctor: 'Dr. Marcos',
    ),
    Room(
      id: 'r-03',
      name: 'Consultorio 03',
      specialty: 'Ginecologia',
      status: 'DISPONIVEL',
      currentDoctor: 'Dra. Patrícia',
    ),
    Room(
      id: 'r-04',
      name: 'Consultorio 04',
      specialty: 'Pediatria',
      status: 'DISPONIVEL',
      currentDoctor: 'Dra. Helena',
    ),
  ];

  @override
  Future<List<QueueTicket>> getQueueTickets({
    String? status,
    String? specialty,
    String? roomId,
    String? search,
  }) async {
    return List<QueueTicket>.unmodifiable(_tickets);
  }

  @override
  Future<List<QueueTicket>> getWaitingQueue() async {
    return _tickets
        .where(
          (t) => t.status == QueueStatus.waiting || t.status == QueueStatus.next,
        )
        .toList();
  }

  @override
  Future<QueueTicket> createTicket(QueueTicket ticket) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _tickets.add(ticket);
    return ticket;
  }

  @override
  Future<QueueTicket> callNextTicket({
    required String roomName,
    String? doctorName,
  }) async {
    final idx = _tickets.indexWhere(
      (t) => t.status == QueueStatus.next || t.status == QueueStatus.waiting,
    );
    if (idx == -1) {
      throw StateError('Nenhum paciente aguardando na fila.');
    }
    final updated = _tickets[idx].copyWith(
      status: QueueStatus.called,
      room: roomName,
      doctorName: doctorName ?? _tickets[idx].doctorName,
      calledAt: DateTime.now(),
    );
    _tickets[idx] = updated;
    return updated;
  }

  @override
  Future<QueueTicket> callTicket({
    required String ticketId,
    required String roomName,
    String? doctorName,
  }) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) throw StateError('Senha não encontrada.');
    final updated = _tickets[idx].copyWith(
      status: QueueStatus.called,
      room: roomName,
      doctorName: doctorName ?? _tickets[idx].doctorName,
      calledAt: DateTime.now(),
    );
    _tickets[idx] = updated;
    return updated;
  }

  @override
  Future<QueueTicket> recallTicket(String ticketId) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) throw StateError('Senha não encontrada.');
    final updated = _tickets[idx].copyWith(calledAt: DateTime.now());
    _tickets[idx] = updated;
    return updated;
  }

  @override
  Future<QueueTicket> startAttendance(String ticketId) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) throw StateError('Senha não encontrada.');
    final updated = _tickets[idx].copyWith(
      status: QueueStatus.inAttendance,
      startedAt: DateTime.now(),
    );
    _tickets[idx] = updated;
    return updated;
  }

  @override
  Future<QueueTicket> finishAttendance({
    required String ticketId,
    String? notes,
    String? cid10,
  }) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) throw StateError('Senha não encontrada.');
    final updated = _tickets[idx].copyWith(
      status: QueueStatus.completed,
      triageNotes: notes ?? _tickets[idx].triageNotes,
      cid10: cid10 ?? _tickets[idx].cid10,
      finishedAt: DateTime.now(),
    );
    _tickets[idx] = updated;
    return updated;
  }

  @override
  Future<QueueTicket> markAbsent(String ticketId) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) throw StateError('Senha não encontrada.');
    final updated = _tickets[idx].copyWith(status: QueueStatus.absent);
    _tickets[idx] = updated;
    return updated;
  }

  @override
  Future<List<Patient>> searchPatients(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <Patient>[];
    const mockPatients = <Patient>[
      Patient(
        id: 'p-01',
        name: 'Benedita Souza Costa',
        cpf: '389.220.198-10',
        cartaoSus: '892441029810001',
        birthDate: '1940-03-12',
        phone: '(98) 99123-4567',
        gender: 'F',
        priorityGroup: 'PREFERENCIAL_80',
        conditions: <String>['HIPERTENSAO', 'DIABETES'],
      ),
    ];
    return mockPatients
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.cpf.toLowerCase().contains(q) ||
              p.cartaoSus.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<Patient> createPatient(Patient patient) async => patient;

  @override
  Future<List<Room>> getRooms() async => _rooms;

  @override
  Future<QueueTicket?> getTvCurrentCall() async {
    final called = _tickets.where(
      (t) =>
          t.status == QueueStatus.called ||
          t.status == QueueStatus.inAttendance,
    );
    return called.isNotEmpty ? called.first : null;
  }

  @override
  Future<List<QueueTicket>> getTvUpcoming() async => getWaitingQueue();
}

final queueRepositoryProvider = Provider<IQueueRepository>((ref) {
  if (EnvConfig.useMockBackend) {
    return MockQueueRepository();
  }
  return RemoteQueueRepository(ref.watch(apiClientProvider));
});
