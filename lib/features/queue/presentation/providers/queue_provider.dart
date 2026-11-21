import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/queue_repository.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/queue_ticket.dart';
import '../../domain/entities/room.dart';

class QueueState {
  const QueueState({
    required this.tickets,
    this.rooms = const <Room>[],
    this.selectedUbs = 'UBS Centro',
    this.selectedSpecialty = 'Todos',
    this.searchQuery = '',
    this.latestCreatedTicket,
    this.selectedCallTicket,
    this.isLoading = false,
    this.isActionLoading = false,
    this.hasLoadedOnce = false,
    this.errorMessage,
  });

  final List<QueueTicket> tickets;
  final List<Room> rooms;
  final String selectedUbs;
  final String selectedSpecialty;
  final String searchQuery;
  final QueueTicket? latestCreatedTicket;
  final QueueTicket? selectedCallTicket;
  final bool isLoading;
  final bool isActionLoading;
  final bool hasLoadedOnce;
  final String? errorMessage;

  /// Pacientes ativos na fila (Em Atendimento, Chamado, Próximo ou Aguardando) filtrados.
  List<QueueTicket> get activeFilteredTickets {
    final q = searchQuery.trim().toLowerCase();
    return tickets.where((t) {
      if (!t.status.isActiveInQueue) return false;
      final matchSpec =
          selectedSpecialty == 'Todos' ||
          _normalize(t.specialty).contains(_normalize(selectedSpecialty));
      final matchQuery =
          q.isEmpty ||
          t.patientName.toLowerCase().contains(q) ||
          t.cpf.toLowerCase().contains(q) ||
          t.ticketCode.toLowerCase().contains(q) ||
          t.susCard.toLowerCase().contains(q);
      return matchSpec && matchQuery;
    }).toList();
  }

  int get waitingCount => tickets
      .where(
        (t) => t.status == QueueStatus.waiting || t.status == QueueStatus.next,
      )
      .length;

  int get inAttendanceCount => tickets
      .where(
        (t) =>
            t.status == QueueStatus.inAttendance ||
            t.status == QueueStatus.called,
      )
      .length;

  int get completedCount =>
      tickets.where((t) => t.status == QueueStatus.completed).length;

  int get absentCount =>
      tickets.where((t) => t.status == QueueStatus.absent).length;

  QueueTicket? get nextInLineTicket {
    final calledList = tickets.where((t) => t.status == QueueStatus.called);
    if (calledList.isNotEmpty) return calledList.first;
    final nextList = tickets.where((t) => t.status == QueueStatus.next);
    if (nextList.isNotEmpty) return nextList.first;
    final waitingList = tickets.where((t) => t.status == QueueStatus.waiting);
    if (waitingList.isNotEmpty) return waitingList.first;
    final activeList = tickets.where(
      (t) => t.status == QueueStatus.inAttendance,
    );
    return activeList.isNotEmpty ? activeList.first : null;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('í', 'i')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c');
  }

  QueueState copyWith({
    List<QueueTicket>? tickets,
    List<Room>? rooms,
    String? selectedUbs,
    String? selectedSpecialty,
    String? searchQuery,
    QueueTicket? latestCreatedTicket,
    QueueTicket? selectedCallTicket,
    bool? isLoading,
    bool? isActionLoading,
    bool? hasLoadedOnce,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QueueState(
      tickets: tickets ?? this.tickets,
      rooms: rooms ?? this.rooms,
      selectedUbs: selectedUbs ?? this.selectedUbs,
      selectedSpecialty: selectedSpecialty ?? this.selectedSpecialty,
      searchQuery: searchQuery ?? this.searchQuery,
      latestCreatedTicket: latestCreatedTicket ?? this.latestCreatedTicket,
      selectedCallTicket: selectedCallTicket ?? this.selectedCallTicket,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class QueueNotifier extends Notifier<QueueState> {
  @override
  QueueState build() {
    return const QueueState(tickets: <QueueTicket>[]);
  }

  IQueueRepository get _repository => ref.read(queueRepositoryProvider);

  String _formatError(Object error) {
    if (error is AppException) return error.message;
    return error.toString();
  }

  /// Carrega a fila atual (priorizada pelo SUS + em atendimento) e salas da API.
  Future<void> loadQueue({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.getWaitingQueue(),
        _repository.getQueueTickets(),
        _repository.getRooms().catchError((_) => const <Room>[]),
      ]);

      final waitingPrioritized = results[0] as List<QueueTicket>;
      final allTickets = results[1] as List<QueueTicket>;
      final rooms = results[2] as List<Room>;

      // Mescla preservando a ordem legal do SUS vinda de /api/tickets/waiting
      // e incluindo senhas CALLED / IN_PROGRESS vindas de /api/tickets.
      final merged = <QueueTicket>[];
      final seenIds = <String>{};

      for (final t in allTickets) {
        if (t.status == QueueStatus.inAttendance ||
            t.status == QueueStatus.called) {
          merged.add(t);
          seenIds.add(t.id);
        }
      }

      var pos = 1;
      for (final t in waitingPrioritized) {
        if (seenIds.add(t.id)) {
          merged.add(
            t.copyWith(
              positionNumber: pos,
              status: pos == 1 ? QueueStatus.next : QueueStatus.waiting,
            ),
          );
          pos++;
        }
      }

      for (final t in allTickets) {
        if (seenIds.add(t.id)) {
          merged.add(t);
        }
      }

      final currentSelected = state.selectedCallTicket;
      QueueTicket? refreshedSelected;
      if (currentSelected != null) {
        final match = merged.where((t) => t.id == currentSelected.id);
        refreshedSelected = match.isNotEmpty ? match.first : currentSelected;
      }

      state = state.copyWith(
        tickets: merged,
        rooms: rooms,
        selectedCallTicket: refreshedSelected,
        isLoading: false,
        hasLoadedOnce: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        errorMessage: _formatError(e),
      );
    }
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

  void selectTicketForCall(QueueTicket ticket) {
    state = state.copyWith(selectedCallTicket: ticket);
  }

  Future<List<Patient>> searchPatients(String query) async {
    try {
      return await _repository.searchPatients(query);
    } catch (_) {
      return const <Patient>[];
    }
  }

  /// Emite uma nova senha via `POST /api/tickets`.
  Future<QueueTicket?> addPatientToQueue({
    required String patientName,
    required String cpf,
    required String birthDate,
    required String specialty,
    required String ubsName,
    required String scheduledDate,
    required String scheduledTime,
    String? patientId,
    String? scheduledDateIso,
    String susCard = '',
    TicketPriority priority = TicketPriority.normal,
    String notes = '',
  }) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final activeCount = state.tickets
          .where((t) => t.status.isActiveInQueue)
          .length;
      final nextPos = activeCount + 1;
      final room = _resolveRoomForSpecialty(specialty);

      final draftTicket = QueueTicket(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        patientId: patientId,
        positionNumber: nextPos,
        ticketCode: '',
        protocol: '',
        patientName: patientName.trim(),
        cpf: cpf.trim(),
        birthDate: birthDate.trim(),
        age: _calculateAge(birthDate),
        susCard: susCard.trim(),
        specialty: specialty,
        room: room,
        ubsName: ubsName,
        scheduledDate: scheduledDate,
        scheduledDateIso: scheduledDateIso,
        scheduledTime: scheduledTime,
        priorityLabel: priority.displayLabel,
        priority: priority,
        triageNotes: notes.trim().isNotEmpty
            ? notes.trim()
            : 'Agendamento $scheduledDate às $scheduledTime ($ubsName)',
        status: QueueStatus.waiting,
      );

      final created = await _repository.createTicket(draftTicket);
      final enriched = created.copyWith(
        positionNumber: created.positionNumber > 0
            ? created.positionNumber
            : nextPos,
        ubsName: ubsName,
        room: created.room.isNotEmpty ? created.room : room,
      );

      state = state.copyWith(
        tickets: <QueueTicket>[...state.tickets, enriched],
        latestCreatedTicket: enriched,
        isActionLoading: false,
        clearError: true,
      );
      return enriched;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _formatError(e),
      );
      return null;
    }
  }

  /// Chama automaticamente o próximo paciente prioritário (`POST /api/tickets/call-next`).
  Future<QueueTicket?> callNext({
    required String roomName,
    String? doctorName,
  }) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final called = await _repository.callNextTicket(
        roomName: roomName,
        doctorName: doctorName,
      );
      _upsertTicket(called, selectForCall: true);
      state = state.copyWith(isActionLoading: false, clearError: true);
      return called;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _formatError(e),
      );
      return null;
    }
  }

  /// Chama uma senha específica para o consultório (`POST /api/tickets/{id}/call`).
  Future<QueueTicket?> callTicket({
    required String ticketId,
    required String roomName,
    String? doctorName,
  }) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final called = await _repository.callTicket(
        ticketId: ticketId,
        roomName: roomName,
        doctorName: doctorName,
      );
      _upsertTicket(called, selectForCall: true);
      state = state.copyWith(isActionLoading: false, clearError: true);
      return called;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _formatError(e),
      );
      return null;
    }
  }

  /// Rechama a senha no Painel da TV (`POST /api/tickets/{id}/recall`).
  Future<bool> recallTicket(String ticketId) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final updated = await _repository.recallTicket(ticketId);
      _upsertTicket(updated, selectForCall: true);
      state = state.copyWith(isActionLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  /// Inicia o atendimento no consultório (`POST /api/tickets/{id}/start`).
  Future<bool> startAttendance(String ticketId) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final updated = await _repository.startAttendance(ticketId);
      _upsertTicket(updated, selectForCall: true);
      state = state.copyWith(isActionLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  /// Finaliza o atendimento com anotações e CID-10 opcionais (`POST /api/tickets/{id}/finish`).
  Future<bool> finishAttendance({
    required String ticketId,
    String? notes,
    String? cid10,
  }) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final updated = await _repository.finishAttendance(
        ticketId: ticketId,
        notes: notes,
        cid10: cid10,
      );
      _upsertTicket(updated);
      state = state.copyWith(isActionLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  /// Marca o paciente como ausente (`POST /api/tickets/{id}/absent`).
  Future<bool> markAbsent(String ticketId) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final updated = await _repository.markAbsent(ticketId);
      _upsertTicket(updated);
      state = state.copyWith(isActionLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  void _upsertTicket(QueueTicket updated, {bool selectForCall = false}) {
    final exists = state.tickets.any((t) => t.id == updated.id);
    final updatedList = exists
        ? state.tickets.map((t) => t.id == updated.id ? updated : t).toList()
        : <QueueTicket>[updated, ...state.tickets];

    final updatedSelected = selectForCall || state.selectedCallTicket?.id == updated.id
        ? updated
        : state.selectedCallTicket;

    state = state.copyWith(
      tickets: updatedList,
      selectedCallTicket: updatedSelected,
    );
  }

  String _resolveRoomForSpecialty(String specialty) {
    final norm = QueueState._normalize(specialty);
    for (final room in state.rooms) {
      if (QueueState._normalize(room.specialty).contains(norm) ||
          norm.contains(QueueState._normalize(room.specialty))) {
        return room.name;
      }
    }
    if (norm.contains('pediatr')) return 'Consultorio 04';
    if (norm.contains('gineco')) return 'Consultorio 03';
    if (norm.contains('dent') || norm.contains('odont')) {
      return 'Consultorio 02';
    }
    return 'Consultorio 01';
  }

  int _calculateAge(String birthDate) {
    final trimmed = birthDate.trim();
    if (trimmed.isEmpty) return 0;
    DateTime? dob;
    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          dob = DateTime(y, m, d);
        }
      }
    } else {
      dob = DateTime.tryParse(trimmed);
    }
    if (dob == null) return 0;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }
}

final queueProvider = NotifierProvider<QueueNotifier, QueueState>(
  QueueNotifier.new,
);
