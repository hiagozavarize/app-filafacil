import 'package:equatable/equatable.dart';

enum QueueStatus {
  inAttendance('Atendendo'),
  next('Próximo'),
  waiting('Aguardando'),
  completed('Concluído'),
  absent('Ausente'),
  cancelled('Cancelado');

  const QueueStatus(this.label);
  final String label;

  bool get isActiveInQueue =>
      this == QueueStatus.inAttendance ||
      this == QueueStatus.next ||
      this == QueueStatus.waiting;
}

/// Entidade que representa um agendamento/senha de paciente na fila da UBS.
/// Mapeável diretamente da tabela `queue_tickets` / endpoints `/queue` e `/history`.
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
    this.doctorName = 'Dr. Roberto Almeida',
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
  final String doctorName;

  String get positionBadge => '#${positionNumber.toString().padLeft(2, '0')}';

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
    String? doctorName,
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
      doctorName: doctorName ?? this.doctorName,
    );
  }

  factory QueueTicket.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'waiting';
    final parsedStatus = QueueStatus.values.firstWhere(
      (s) => s.name == statusName || s.label == statusName,
      orElse: () => QueueStatus.waiting,
    );
    return QueueTicket(
      id: json['id'] as String? ?? '',
      positionNumber: json['position_number'] as int? ?? 1,
      ticketCode: json['ticket_code'] as String? ?? 'CG-001',
      protocol: json['protocol'] as String? ?? '#2026-0892',
      patientName: json['patient_name'] as String? ?? '',
      cpf: json['cpf'] as String? ?? '',
      birthDate: json['birth_date'] as String? ?? '01/01/1980',
      age: json['age'] as int? ?? 45,
      susCard: json['sus_card'] as String? ?? '898 0012 3456 7890',
      specialty: json['specialty'] as String? ?? 'Clínico Geral',
      room: json['room'] as String? ?? 'Sala 02',
      ubsName: json['ubs_name'] as String? ?? 'UBS Centro',
      scheduledDate: json['scheduled_date'] as String? ?? '19 Nov 2026',
      scheduledTime: json['scheduled_time'] as String? ?? '07:00',
      priorityLabel: json['priority_label'] as String? ?? 'Atendimento Regular',
      triageNotes:
          json['triage_notes'] as String? ?? 'Consulta agendada via FilaFácil',
      status: parsedStatus,
      doctorName: json['doctor_name'] as String? ?? 'Dr. Roberto Almeida',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'position_number': positionNumber,
      'ticket_code': ticketCode,
      'protocol': protocol,
      'patient_name': patientName,
      'cpf': cpf,
      'birth_date': birthDate,
      'age': age,
      'sus_card': susCard,
      'specialty': specialty,
      'room': room,
      'ubs_name': ubsName,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'priority_label': priorityLabel,
      'triage_notes': triageNotes,
      'status': status.name,
      'doctor_name': doctorName,
    };
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
    doctorName,
  ];
}

