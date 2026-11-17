import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/queue_repository.dart';
import '../../domain/entities/queue_ticket.dart';

class QueueState {
  const QueueState({
    required this.tickets,
    this.selectedUbs = 'UBS Centro',
    this.selectedSpecialty = 'Todos',
    this.searchQuery = '',
    this.historyFilter = 'Todos',
    this.historySearchQuery = '',
    this.latestCreatedTicket,
    this.selectedCallTicket,
  });

  final List<QueueTicket> tickets;
  final String selectedUbs;
  final String selectedSpecialty;
  final String searchQuery;
  final String historyFilter;
  final String historySearchQuery;
  final QueueTicket? latestCreatedTicket;
  final QueueTicket? selectedCallTicket;

  /// Pacientes ativos na fila (Em Atendimento, Próximo ou Aguardando) filtrados.
  List<QueueTicket> get activeFilteredTickets {
    final q = searchQuery.trim().toLowerCase();
    return tickets.where((t) {
      if (!t.status.isActiveInQueue) return false;
      final matchSpec =
          selectedSpecialty == 'Todos' ||
          t.specialty.toLowerCase().contains(selectedSpecialty.toLowerCase());
      final matchQuery =
          q.isEmpty ||
          t.patientName.toLowerCase().contains(q) ||
          t.cpf.toLowerCase().contains(q) ||
          t.ticketCode.toLowerCase().contains(q);
      return matchSpec && matchQuery;
    }).toList();
  }

  /// Registros do Histórico (Concluído, Ausente, Cancelado) filtrados.
  List<QueueTicket> get historyFilteredTickets {
    final q = historySearchQuery.trim().toLowerCase();
    return tickets.where((t) {
      if (t.status.isActiveInQueue) return false;
      final matchFilter = switch (historyFilter) {
        'Concluídos' => t.status == QueueStatus.completed,
        'Ausentes' =>
          t.status == QueueStatus.absent || t.status == QueueStatus.cancelled,
        _ => true,
      };
      final matchQuery =
          q.isEmpty ||
          t.patientName.toLowerCase().contains(q) ||
          t.cpf.toLowerCase().contains(q) ||
          t.protocol.toLowerCase().contains(q);
      return matchFilter && matchQuery;
    }).toList();
  }

  int get waitingCount => tickets
      .where(
        (t) => t.status == QueueStatus.waiting || t.status == QueueStatus.next,
      )
      .length;

  int get inAttendanceCount =>
      tickets.where((t) => t.status == QueueStatus.inAttendance).length;

  int get completedCount =>
      tickets.where((t) => t.status == QueueStatus.completed).length;

  int get absentCount =>
      tickets.where((t) => t.status == QueueStatus.absent).length;

  QueueTicket? get nextInLineTicket {
    final nextList = tickets.where((t) => t.status == QueueStatus.next);
    if (nextList.isNotEmpty) return nextList.first;
    final waitingList = tickets.where((t) => t.status == QueueStatus.waiting);
    if (waitingList.isNotEmpty) return waitingList.first;
    final activeList = tickets.where(
      (t) => t.status == QueueStatus.inAttendance,
    );
    return activeList.isNotEmpty ? activeList.first : null;
  }

  QueueState copyWith({
    List<QueueTicket>? tickets,
    String? selectedUbs,
    String? selectedSpecialty,
    String? searchQuery,
    String? historyFilter,
    String? historySearchQuery,
    QueueTicket? latestCreatedTicket,
    QueueTicket? selectedCallTicket,
  }) {
    return QueueState(
      tickets: tickets ?? this.tickets,
      selectedUbs: selectedUbs ?? this.selectedUbs,
      selectedSpecialty: selectedSpecialty ?? this.selectedSpecialty,
      searchQuery: searchQuery ?? this.searchQuery,
      historyFilter: historyFilter ?? this.historyFilter,
      historySearchQuery: historySearchQuery ?? this.historySearchQuery,
      latestCreatedTicket: latestCreatedTicket ?? this.latestCreatedTicket,
      selectedCallTicket: selectedCallTicket ?? this.selectedCallTicket,
    );
  }
}

class QueueNotifier extends Notifier<QueueState> {
  @override
  QueueState build() {
    final initialTickets = _initialSyncTickets();
    return QueueState(
      tickets: initialTickets,
      selectedCallTicket: initialTickets.first,
    );
  }

  IQueueRepository get _repository => ref.read(queueRepositoryProvider);

  List<QueueTicket> _initialSyncTickets() {
    return const <QueueTicket>[
      QueueTicket(
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
        triageNotes: 'Controle de PA e receita',
        status: QueueStatus.inAttendance,
        doctorName: 'Dr. Roberto',
      ),
      QueueTicket(
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
        triageNotes: 'Avaliação clínica de rotina',
        status: QueueStatus.next,
        doctorName: 'Dr. Roberto',
      ),
      QueueTicket(
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
        triageNotes: 'Acompanhamento pediátrico e vacinas',
        status: QueueStatus.waiting,
        doctorName: 'Dra. Helena',
      ),
      QueueTicket(
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
      QueueTicket(
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
      QueueTicket(
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
      QueueTicket(
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
        triageNotes: 'Paciente não respondeu à chamada',
        status: QueueStatus.absent,
      ),
      QueueTicket(
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
      QueueTicket(
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
  }

  void setSelectedUbs(String ubs) {
    state = state.copyWith(selectedUbs: ubs);
  }

  void setSelectedSpecialty(String specialty) {
    state = state.copyWith(selectedSpecialty: specialty);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setHistoryFilter(String filter) {
    state = state.copyWith(historyFilter: filter);
  }

  void setHistorySearchQuery(String query) {
    state = state.copyWith(historySearchQuery: query);
  }

  void selectTicketForCall(QueueTicket ticket) {
    state = state.copyWith(selectedCallTicket: ticket);
  }

  Future<QueueTicket> addPatientToQueue({
    required String patientName,
    required String cpf,
    required String birthDate,
    required String specialty,
    required String ubsName,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    final activeCount = state.tickets
        .where((t) => t.status.isActiveInQueue)
        .length;
    final nextPos = activeCount + 1;
    final prefix = switch (specialty) {
      'Pediatra' => 'PD',
      'Ginecologista' => 'GN',
      'Dentista' => 'OD',
      _ => 'CG',
    };
    final room = switch (specialty) {
      'Pediatra' => 'Sala 04',
      'Ginecologista' => 'Sala 03',
      'Dentista' => 'Sala 01',
      _ => 'Sala 02',
    };

    final newTicket = QueueTicket(
      id: 'q-${DateTime.now().millisecondsSinceEpoch}',
      positionNumber: nextPos,
      ticketCode: '$prefix-${(10 + nextPos).toString().padLeft(3, '0')}',
      protocol: '#2026-089${nextPos + 1}',
      patientName: patientName.trim().isEmpty
          ? 'José Maria da Silva'
          : patientName.trim(),
      cpf: cpf.trim().isEmpty ? '412.890.123-00' : cpf.trim(),
      birthDate: birthDate.trim().isEmpty ? '12/05/1985' : birthDate.trim(),
      age: 41,
      susCard: '898 0014 2289 7741',
      specialty: specialty,
      room: room,
      ubsName: ubsName,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      priorityLabel: 'Atendimento Regular',
      triageNotes: 'Agendado pelo Agente de Saúde',
      status: QueueStatus.waiting,
    );

    final created = await _repository.createTicket(newTicket);
    final updatedList = <QueueTicket>[...state.tickets, created];
    state = state.copyWith(
      tickets: updatedList,
      latestCreatedTicket: created,
    );
    return created;
  }

  Future<void> updateStatus(String ticketId, QueueStatus newStatus) async {
    await _repository.updateTicketStatus(
      ticketId: ticketId,
      newStatus: newStatus,
    );
    final updatedList = state.tickets.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(status: newStatus);
      }
      return t;
    }).toList();

    final updatedSelected = state.selectedCallTicket?.id == ticketId
        ? state.selectedCallTicket?.copyWith(status: newStatus)
        : state.selectedCallTicket;

    state = state.copyWith(
      tickets: updatedList,
      selectedCallTicket: updatedSelected,
    );
  }
}

final queueProvider = NotifierProvider<QueueNotifier, QueueState>(
  QueueNotifier.new,
);
