import 'package:equatable/equatable.dart';

import '../../../../core/utils/input_formatters.dart';

/// Prioridade legal do SUS mapeada para o backend (`priority` + `specialCondition`).
enum TicketPriority {
  normal('NORMAL', 'Normal', 'Atendimento Regular', null),
  preferencial60(
    'PREFERENCIAL_60',
    'Idoso 60+',
    'Prioridade: Idoso 60+',
    'Idoso 60+',
  ),
  preferencial80(
    'PREFERENCIAL_80',
    'Idoso 80+',
    'Prioridade: Idoso 80+',
    'Idoso 80+',
  ),
  gestante('PREFERENCIAL', 'Gestante', 'Prioridade: Gestante', 'Gestante'),
  pcd('PREFERENCIAL', 'PCD', 'Prioridade: Pessoa com Deficiência', 'PCD'),
  urgenciaManchester(
    'URGENCIA_MANCHESTER',
    'Urgência',
    'Urgência (Protocolo Manchester)',
    'Urgência Manchester',
  );

  const TicketPriority(
    this.apiValue,
    this.shortLabel,
    this.displayLabel,
    this.specialConditionValue,
  );

  final String apiValue;
  final String shortLabel;
  final String displayLabel;
  final String? specialConditionValue;

  static TicketPriority fromApi(String? value, {String? label}) {
    final combined = '${value ?? ''} ${label ?? ''}'.trim().toUpperCase();
    if (combined.contains('URG') || combined.contains('MANCHESTER')) {
      return TicketPriority.urgenciaManchester;
    }
    if (combined.contains('80')) {
      return TicketPriority.preferencial80;
    }
    if (combined.contains('GESTANTE')) {
      return TicketPriority.gestante;
    }
    if (combined.contains('PCD') || combined.contains('DEFICIENTE')) {
      return TicketPriority.pcd;
    }
    if (combined.contains('60') || combined.contains('PREF')) {
      return TicketPriority.preferencial60;
    }
    return TicketPriority.normal;
  }
}

/// Status do ciclo de atendimento mapeado para os enums da API (PT-BR e EN).
enum QueueStatus {
  inAttendance('Atendendo', 'EM_ATENDIMENTO'),
  called('Chamado', 'CHAMADO'),
  next('Próximo', 'AGUARDANDO'),
  waiting('Aguardando', 'AGUARDANDO'),
  completed('Concluído', 'FINALIZADO'),
  absent('Ausente', 'AUSENTE'),
  cancelled('Cancelado', 'CANCELADO');

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
      'EM_ATENDIMENTO' ||
      'IN_PROGRESS' ||
      'INATTENDANCE' ||
      'ATENDENDO' => QueueStatus.inAttendance,
      'CHAMANDO' || 'CHAMADO' || 'CALLED' => QueueStatus.called,
      'NEXT' || 'PRÓXIMO' || 'PROXIMO' => QueueStatus.next,
      'AGUARDANDO' || 'TRIAGEM' || 'WAITING' => QueueStatus.waiting,
      'FINALIZADO' ||
      'FINISHED' ||
      'COMPLETED' ||
      'CONCLUÍDO' ||
      'CONCLUIDO' => QueueStatus.completed,
      'AUSENTE' || 'ABSENT' => QueueStatus.absent,
      'CANCELADO' || 'CANCELLED' || 'CANCELED' => QueueStatus.cancelled,
      _ => QueueStatus.waiting,
    };
  }
}

/// Entidade que representa uma senha/ticket na fila da UBS (`Ticket` no backend Prisma).
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
    this.patientId,
    this.scheduledDateIso,
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
  final String? patientId;
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
  final String? scheduledDateIso;
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

  String get positionBadge => ticketCode.isNotEmpty
      ? ticketCode
      : '#${positionNumber.toString().padLeft(2, '0')}';

  QueueTicket copyWith({
    String? id,
    String? patientId,
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
    String? scheduledDateIso,
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
      patientId: patientId ?? this.patientId,
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
      scheduledDateIso: scheduledDateIso ?? this.scheduledDateIso,
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

  static int _computeAgeFromBirthDate(String rawBirthDate) {
    final iso = formatBirthDateToIso(rawBirthDate);
    if (iso == null) return 0;
    final dob = DateTime.tryParse(iso);
    if (dob == null) return 0;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
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
    final rawPriorityLabel =
        (json['priorityLabel'] as String?) ??
        (json['priority_label'] as String?);
    final priority = TicketPriority.fromApi(
      json['priority'] as String? ?? json['priorityGroup'] as String?,
      label: rawPriorityLabel,
    );
    final status = QueueStatus.fromApi(json['status'] as String?);
    final createdAt = _parseDate(json['createdAt'] ?? json['created_at']);
    final scheduledAt = _parseDate(json['scheduledAt']);
    final calledAt = _parseDate(json['calledAt'] ?? json['called_at']);
    final startedAt = _parseDate(
      json['attendedAt'] ?? json['startedAt'] ?? json['started_at'],
    );
    final finishedAt = _parseDate(json['finishedAt'] ?? json['finished_at']);

    final rawSpecialty =
        (json['serviceLabel'] as String?)?.trim() ??
        (json['specialty'] as String?)?.trim() ??
        (json['service'] as String?)?.trim();
    final specialty = (rawSpecialty != null && rawSpecialty.isNotEmpty)
        ? rawSpecialty
        : 'Clínica Geral';

    final rawRoom =
        (json['room'] as String?)?.trim() ??
        (json['roomName'] as String?)?.trim();
    final room = (rawRoom != null && rawRoom.isNotEmpty)
        ? rawRoom
        : _defaultRoomForSpecialty(specialty);

    final rawDoctor =
        (json['professional'] as String?)?.trim() ??
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

    final displayDate = scheduledAt ?? createdAt ?? DateTime.now();
    final scheduledDate =
        (json['scheduled_date'] as String?) ?? _formatShortDate(displayDate);
    final scheduledTime =
        (json['scheduled_time'] as String?) ?? _formatTime(displayDate);

    final patientMap = json['patient'] as Map<String, dynamic>?;
    final rawBirthDate =
        (json['birthDate'] as String?) ??
        (json['birth_date'] as String?) ??
        (patientMap?['birthDate'] as String?) ??
        '';
    final formattedBirth = formatBirthDateToBr(rawBirthDate);
    final parsedAge =
        (json['age'] as num?)?.toInt() ?? _computeAgeFromBirthDate(rawBirthDate);

    return QueueTicket(
      id: id,
      patientId: json['patientId'] as String? ?? patientMap?['id'] as String?,
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
      birthDate: formattedBirth,
      age: parsedAge,
      susCard:
          (json['cartaoSus'] as String?) ??
          (json['susCard'] as String?) ??
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
      priorityLabel: (rawPriorityLabel != null && rawPriorityLabel.isNotEmpty)
          ? rawPriorityLabel
          : priority.displayLabel,
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
      serviceDurationMinutes:
          (json['consultationTimeMinutes'] as num?) ??
          (json['serviceDurationMinutes'] as num?),
      cid10: (json['cid'] as String?) ?? (json['cid10'] as String?),
      createdAt: createdAt,
    );
  }

  /// Payload completo aceito por `POST /api/tickets` no backend (`TicketController.createTicket`).
  /// Envia `birthDate` em formato ISO (`YYYY-MM-DD`) para que o backend calcule e salve `age`
  /// e exiba corretamente a idade do paciente no dashboard web.
  Map<String, dynamic> toCreateTicketPayload() {
    final isoBirthDate = formatBirthDateToIso(birthDate);
    final cleanSus = digitsOnly(susCard);
    return <String, dynamic>{
      if (patientId != null && patientId!.trim().isNotEmpty)
        'patientId': patientId!.trim(),
      'patientName': patientName.trim(),
      if (cpf.trim().isNotEmpty) 'cpf': formatCpf(cpf),
      if (cleanSus.isNotEmpty) 'cartaoSus': cleanSus,
      if (isoBirthDate != null)
        'birthDate': isoBirthDate
      else if (birthDate.trim().isNotEmpty)
        'birthDate': birthDate.trim(),
      'priority': priority.apiValue,
      if (priority.specialConditionValue != null)
        'specialCondition': priority.specialConditionValue,
      if (specialty.trim().isNotEmpty) 'service': specialty.trim(),
      if (specialty.trim().isNotEmpty) 'specialty': specialty.trim(),
      if (room.trim().isNotEmpty) 'room': room.trim(),
      if (scheduledDateIso != null && scheduledDateIso!.isNotEmpty)
        'scheduledDate': scheduledDateIso,
      if (scheduledTime.trim().isNotEmpty)
        'scheduledTime': scheduledTime.trim(),
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
    patientId,
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
    scheduledDateIso,
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
