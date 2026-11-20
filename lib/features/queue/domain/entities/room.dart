import 'package:equatable/equatable.dart';

/// Entidade de consultório/sala retornada por `/api/rooms`.
class Room extends Equatable {
  const Room({
    required this.id,
    required this.name,
    required this.specialty,
    this.status = 'DISPONIVEL',
    this.currentDoctor,
  });

  final String id;
  final String name;
  final String specialty;
  final String status;
  final String? currentDoctor;

  bool get isAvailable => status.toUpperCase() == 'DISPONIVEL';

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? 'Consultorio 01',
      specialty: json['specialty'] as String? ?? 'Clinica Geral',
      status: json['status'] as String? ?? 'DISPONIVEL',
      currentDoctor: json['currentDoctor'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'specialty': specialty,
    };
  }

  @override
  List<Object?> get props => [id, name, specialty, status, currentDoctor];
}
