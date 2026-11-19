import 'package:equatable/equatable.dart';

/// Entidade que representa o Agente Comunitário de Saúde autenticado no FilaFácil UBS.
/// Mapeável diretamente da tabela `health_agents` / endpoint `/agents/me`.
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
  final bool isActive;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'AG';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
      isActive: isActive ?? this.isActive,
    );
  }

  factory HealthAgent.fromJson(Map<String, dynamic> json) {
    return HealthAgent(
      id: json['id'] as String? ?? 'agent-01',
      name: json['name'] as String? ?? 'Hiago Zavarize',
      cpf: json['cpf'] as String? ?? '042.891.653-20',
      email: json['email'] as String? ?? 'hiago.zavarize@saude.ubs.gov.br',
      phone: json['phone'] as String? ?? '(99) 98412-5590',
      cns: json['cns'] as String? ?? '704.8921.3301',
      role: json['role'] as String? ?? 'Agente de Saúde',
      assignedUbs: json['assigned_ubs'] as String? ?? 'UBS Centro',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'cpf': cpf,
      'email': email,
      'phone': phone,
      'cns': cns,
      'role': role,
      'assigned_ubs': assignedUbs,
      'is_active': isActive,
    };
  }

  static const HealthAgent defaultMock = HealthAgent(
    id: 'agent-01',
    name: 'Hiago Zavarize',
    cpf: '042.891.653-20',
    email: 'hiago.zavarize@saude.ubs.gov.br',
    phone: '(99) 98412-5590',
    cns: '704.8921.3301',
    role: 'Agente de Saúde',
    assignedUbs: 'UBS Centro',
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
    isActive,
  ];
}

