import 'package:equatable/equatable.dart';

/// Prioridade legal do SUS mapeada diretamente para o enum `priority` da API `/api/tickets`.
enum TicketPriority {
  normal('NORMAL', 'Normal', 'Atendimento Regular'),
  preferencial60('PREFERENCIAL_60', 'Idoso 60+', 'Prioridade: Idoso 60+'),
  preferencial80('PREFERENCIAL_80', 'Idoso 80+', 'Prioridade: Idoso 80+'),
  gestante('GESTANTE', 'Gestante', 'Prioridade: Gestante'),
  pcd('PCD', 'PCD', 'Prioridade: Pessoa com Deficiência'),
  urgenciaManchester(
    'URGENCIA_MANCHESTER',
    'Urgência',
    'Urgência (Protocolo Manchester)',
  );

  const TicketPriority(this.apiValue, this.shortLabel, this.displayLabel);

  final String apiValue;
  final String shortLabel;
  final String displayLabel;

  static TicketPriority fromApi(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    return TicketPriority.values.firstWhere(
      (p) => p.apiValue == normalized || p.name.toUpperCase() == normalized,
      orElse: () => TicketPriority.normal,
    );
  }
}

/// Status do ciclo de atendimento mapeado 1:1 para o enum `status` da API `/api/tickets`.
enum QueueStatus {
  inAttendance('Atendendo', 'IN_PROGRESS'),
  called('Chamado', 'CALLED'),
  next('Próximo', 'WAITING'),
  waiting('Aguardando', 'WAITING'),
  completed('Concluído', 'FINISHED'),
  absent('Ausente', 'ABSENT'),
  cancelled('Cancelado', 'CANCELLED');

  const QueueStatus(this.label, this.apiValue);

  final String label;
  final String apiValue;

  bool get isActiveInQueue =>
      this == QueueStatus.inAttendance ||
      this == QueueStatus.called ||
      this == QueueStatus.next ||
      this == QueueStatus.waiting;

  static QueueStatus fromApi(String? raw) {
    final value = (raw ?? '').trim().toUpperCase();
    return switch (value) {
      'IN_PROGRESS' || 'INATTENDANCE' || 'ATENDENDO' => QueueStatus.inAttendance,
      'CALLED' || 'CHAMADO' => QueueStatus.called,
      'NEXT' || 'PRÓXIMO' || 'PROXIMO' => QueueStatus.next,
      'WAITING' || 'AGUARDANDO' => QueueStatus.waiting,
      'FINISHED' || 'COMPLETED' || 'CONCLUÍDO' || 'CONCLUIDO' =>
        QueueStatus.completed,
      'ABSENT' || 'AUSENTE' => QueueStatus.absent,
      'CANCELLED' || 'CANCELED' || 'CANCELADO' => QueueStatus.cancelled,
      _ => QueueStatus.waiting,
    };
  }
}

/// Entidade que representa uma senha/ticket na fila da UBS (`Ticket` no Swagger).
class QueueTicket extends Equatable {
  const QueueTicket({
    required this.id,
    required this.positionNumber,
    required this.ticketCode,
    required this.protocol,
    required this.patientName,
    required this.cpf,
    required this.birthDate,
    required this.age,
    required this.susCard,
    required this.specialty,
    required this.room,
    required this.ubsName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.priorityLabel,
    required this.triageNotes,
    required this.status,
    this.priority = TicketPriority.normal,
    this.doctorName = 'Equipe UBS',
    this.calledAt,
    this.startedAt,
    this.finishedAt,
    this.waitTimeMinutes,
    this.serviceDurationMinutes,
    this.cid10,
    this.createdAt,
  });

  final String id;
  final int positionNumber;
  final String ticketCode;
  final String protocol;
  final String patientName;
  final String cpf;
  final String birthDate;
  final int age;
  final String susCard;
  final String specialty;
  final String room;
  final String ubsName;
  final String scheduledDate;
  final String scheduledTime;
  final String priorityLabel;
  final String triageNotes;
  final QueueStatus status;
  final TicketPriority priority;
  final String doctorName;
  final DateTime? calledAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final num? waitTimeMinutes;
  final num? serviceDurationMinutes;
  final String? cid10;
  final DateTime? createdAt;

  String get positionBadge =>
      ticketCode.isNotEmpty ? ticketCode : '#${positionNumber.toString().padLeft(2, '0')}';

  QueueTicket copyWith({
    String? id,
    int? positionNumber,
    String? ticketCode,
    String? protocol,
    String? patientName,
    String? cpf,
    String? birthDate,
    int? age,
    String? susCard,
    String? specialty,
    String? room,
    String? ubsName,
    String? scheduledDate,
    String? scheduledTime,
    String? priorityLabel,
    String? triageNotes,
    QueueStatus? status,
    TicketPriority? priority,
    String? doctorName,
    DateTime? calledAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    num? waitTimeMinutes,
    num? serviceDurationMinutes,
    String? cid10,
    DateTime? createdAt,
  }) {
    return QueueTicket(
      id: id ?? this.id,
      positionNumber: positionNumber ?? this.positionNumber,
      ticketCode: ticketCode ?? this.ticketCode,
      protocol: protocol ?? this.protocol,
      patientName: patientName ?? this.patientName,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      susCard: susCard ?? this.susCard,
      specialty: specialty ?? this.specialty,
      room: room ?? this.room,
      ubsName: ubsName ?? this.ubsName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      triageNotes: triageNotes ?? this.triageNotes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      doctorName: doctorName ?? this.doctorName,
      calledAt: calledAt ?? this.calledAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      waitTimeMinutes: waitTimeMinutes ?? this.waitTimeMinutes,
      serviceDurationMinutes:
          serviceDurationMinutes ?? this.serviceDurationMinutes,
      cid10: cid10 ?? this.cid10,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal();
    }
    return null;
  }

  static String _formatShortDate(DateTime dt) {
    const months = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  factory QueueTicket.fromJson(
    Map<String, dynamic> json, {
    int? fallbackPosition,
    String fallbackUbs = 'UBS Centro',
  }) {
    final id = (json['id'] ?? '').toString();
    final code =
        (json['code'] as String?) ??
        (json['ticket_code'] as String?) ??
        'SEN-001';
    final priority = TicketPriority.fromApi(
      json['priority'] as String? ?? json['priorityGroup'] as String?,
    );
    final status = QueueStatus.fromApi(json['status'] as String?);
    final createdAt = _parseDate(json['createdAt'] ?? json['created_at']);
    final calledAt = _parseDate(json['calledAt'] ?? json['called_at']);
    final startedAt = _parseDate(json['startedAt'] ?? json['started_at']);
    final finishedAt = _parseDate(json['finishedAt'] ?? json['finished_at']);

    final rawSpecialty = (json['specialty'] as String?)?.trim();
    final specialty = (rawSpecialty != null && rawSpecialty.isNotEmpty)
        ? rawSpecialty
        : 'Clínica Geral';

    final rawRoom =
        (json['roomName'] as String?)?.trim() ??
        (json['room'] as String?)?.trim();
    final room = (rawRoom != null && rawRoom.isNotEmpty)
        ? rawRoom
        : _defaultRoomForSpecialty(specialty);

    final rawDoctor =
        (json['doctorName'] as String?)?.trim() ??
        (json['doctor_name'] as String?)?.trim();
    final doctorName = (rawDoctor != null && rawDoctor.isNotEmpty)
        ? rawDoctor
        : 'Equipe UBS';

    final rawProtocol = (json['protocol'] as String?)?.trim();
    final shortId = id.length >= 6 ? id.substring(0, 6).toUpperCase() : id;
    final protocol = (rawProtocol != null && rawProtocol.isNotEmpty)
        ? rawProtocol
        : (code.isNotEmpty ? '#$code' : '#$shortId');

    final scheduledDate =
        (json['scheduled_date'] as String?) ??
        (createdAt != null ? _formatShortDate(createdAt) : _formatShortDate(DateTime.now()));
    final scheduledTime =
        (json['scheduled_time'] as String?) ??
        (createdAt != null ? _formatTime(createdAt) : _formatTime(DateTime.now()));

    return QueueTicket(
      id: id,
      positionNumber:
          (json['position_number'] as num?)?.toInt() ??
          (json['position'] as num?)?.toInt() ??
          fallbackPosition ??
          1,
      ticketCode: code,
      protocol: protocol,
      patientName:
          (json['patientName'] as String?) ??
          (json['patient_name'] as String?) ??
          'Paciente',
      cpf: (json['cpf'] as String?) ?? '',
      birthDate: (json['birthDate'] as String?) ??
          (json['birth_date'] as String?) ??
          '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      susCard:
          (json['cartaoSus'] as String?) ??
          (json['sus_card'] as String?) ??
          '',
      specialty: specialty,
      room: room,
      ubsName:
          (json['unitName'] as String?) ??
          (json['ubs_name'] as String?) ??
          fallbackUbs,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      priorityLabel:
          (json['priority_label'] as String?) ?? priority.displayLabel,
      triageNotes:
          (json['notes'] as String?) ??
          (json['triage_notes'] as String?) ??
          'Acolhimento via FilaFácil UBS',
      status: status,
      priority: priority,
      doctorName: doctorName,
      calledAt: calledAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
      waitTimeMinutes: json['waitTimeMinutes'] as num?,
      serviceDurationMinutes: json['serviceDurationMinutes'] as num?,
      cid10: json['cid10'] as String?,
      createdAt: createdAt,
    );
  }

  /// Payload exato aceito por `POST /api/tickets`.
  Map<String, dynamic> toCreateTicketPayload() {
    return <String, dynamic>{
      'patientName': patientName.trim(),
      if (cpf.trim().isNotEmpty) 'cpf': cpf.trim(),
      if (susCard.trim().isNotEmpty) 'cartaoSus': susCard.trim(),
      'priority': priority.apiValue,
      if (specialty.trim().isNotEmpty) 'specialty': specialty.trim(),
      if (triageNotes.trim().isNotEmpty) 'notes': triageNotes.trim(),
    };
  }

  static String _defaultRoomForSpecialty(String specialty) {
    final lower = specialty.toLowerCase();
    if (lower.contains('pediatr')) return 'Consultorio 04';
    if (lower.contains('gineco')) return 'Consultorio 03';
    if (lower.contains('dent') || lower.contains('odont')) {
      return 'Consultorio 02';
    }
    return 'Consultorio 01';
  }

  @override
  List<Object?> get props => [
    id,
    positionNumber,
    ticketCode,
    protocol,
    patientName,
    cpf,
    birthDate,
    age,
    susCard,
    specialty,
    room,
    ubsName,
    scheduledDate,
    scheduledTime,
    priorityLabel,
    triageNotes,
    status,
    priority,
    doctorName,
    calledAt,
    startedAt,
    finishedAt,
    waitTimeMinutes,
    serviceDurationMinutes,
    cid10,
    createdAt,
  ];
}
