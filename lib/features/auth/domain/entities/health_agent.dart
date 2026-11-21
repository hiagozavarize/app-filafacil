import 'package:equatable/equatable.dart';

/// Entidade que representa o operador / profissional de saúde autenticado
/// no FilaFácil UBS (schema `User` da API `/api/users/profile` e `/api/auth/login`).
class HealthAgent extends Equatable {
  const HealthAgent({
    required this.id,
    required this.name,
    required this.cpf,
    required this.email,
    required this.phone,
    required this.cns,
    required this.role,
    required this.assignedUbs,
    this.registration = '',
    this.avatarUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String cpf;
  final String email;
  final String phone;
  final String cns;
  final String role;
  final String assignedUbs;
  final String registration;
  final String? avatarUrl;
  final bool isActive;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'AG';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Rótulo amigável do cargo vindo da API (`MEDICO`, `RECEPCAO`, `ENFERMEIRO`, `COORDENADORA`).
  String get roleDisplayLabel {
    return switch (role.toUpperCase()) {
      'ADMIN' || 'ADM' || 'ADMINISTRADOR' => 'Administrador',
      'MEDICO' => 'Médico(a)',
      'ENFERMEIRO' => 'Enfermeiro(a)',
      'RECEPCAO' => 'Recepção / Triagem',
      'COORDENADORA' || 'COORDENADOR' => 'Coordenação UBS',
      'AGENTE_SAUDE' || 'ACS' => 'Agente de Saúde',
      _ => role.isEmpty ? 'Agente de Saúde' : role,
    };
  }

  HealthAgent copyWith({
    String? id,
    String? name,
    String? cpf,
    String? email,
    String? phone,
    String? cns,
    String? role,
    String? assignedUbs,
    String? registration,
    String? avatarUrl,
    bool? isActive,
  }) {
    return HealthAgent(
      id: id ?? this.id,
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cns: cns ?? this.cns,
      role: role ?? this.role,
      assignedUbs: assignedUbs ?? this.assignedUbs,
      registration: registration ?? this.registration,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  factory HealthAgent.fromJson(Map<String, dynamic> json) {
    final unit =
        (json['unitName'] as String?) ??
        (json['assigned_ubs'] as String?) ??
        'UBS Centro';
    return HealthAgent(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] as String? ?? '').trim().isNotEmpty
          ? (json['name'] as String).trim()
          : 'Profissional SUS',
      cpf: json['cpf'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      cns: json['cns'] as String? ?? '',
      role: json['role'] as String? ?? 'RECEPCAO',
      assignedUbs: unit.trim().isNotEmpty ? unit.trim() : 'UBS Centro',
      registration: json['registration'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  /// Payload completo para serialização local.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'cpf': cpf,
      'email': email,
      'phone': phone,
      'cns': cns,
      'role': role,
      'unitName': assignedUbs,
      'registration': registration,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isActive': isActive,
    };
  }

  /// Payload exato aceito por `PUT /api/users/profile`.
  Map<String, dynamic> toProfileUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'phone': phone,
      'role': role,
      'unitName': assignedUbs,
      'registration': registration,
    };
  }

  static const HealthAgent defaultMock = HealthAgent(
    id: 'agent-01',
    name: 'Hiago Zavarize',
    cpf: '042.891.653-20',
    email: 'hiago.zavarize@saude.ubs.gov.br',
    phone: '(99) 98412-5590',
    cns: '704.8921.3301',
    role: 'RECEPCAO',
    assignedUbs: 'UBS Centro',
    registration: 'SUS-MA 00412',
  );

  @override
  List<Object?> get props => [
    id,
    name,
    cpf,
    email,
    phone,
    cns,
    role,
    assignedUbs,
    registration,
    avatarUrl,
    isActive,
  ];
}
