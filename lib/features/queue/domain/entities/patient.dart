import 'package:equatable/equatable.dart';

/// Entidade de paciente do CADSUS retornada por `/api/patients` e `/api/patients/search`.
class Patient extends Equatable {
  const Patient({
    required this.id,
    required this.name,
    this.cpf = '',
    this.cartaoSus = '',
    this.birthDate = '',
    this.phone = '',
    this.gender = '',
    this.priorityGroup = 'NORMAL',
    this.conditions = const <String>[],
  });

  final String id;
  final String name;
  final String cpf;
  final String cartaoSus;
  final String birthDate;
  final String phone;
  final String gender;
  final String priorityGroup;
  final List<String> conditions;

  factory Patient.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['conditions'];
    final conditionsList = rawConditions is List
        ? rawConditions.map((e) => e.toString()).toList()
        : const <String>[];

    return Patient(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] as String? ?? '').trim(),
      cpf: json['cpf'] as String? ?? '',
      cartaoSus: json['cartaoSus'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      priorityGroup: json['priorityGroup'] as String? ?? 'NORMAL',
      conditions: conditionsList,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      if (cpf.isNotEmpty) 'cpf': cpf,
      if (cartaoSus.isNotEmpty) 'cartaoSus': cartaoSus,
      if (birthDate.isNotEmpty) 'birthDate': birthDate,
      if (phone.isNotEmpty) 'phone': phone,
      if (gender.isNotEmpty) 'gender': gender,
      'priorityGroup': priorityGroup,
      if (conditions.isNotEmpty) 'conditions': conditions,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    cpf,
    cartaoSus,
    birthDate,
    phone,
    gender,
    priorityGroup,
    conditions,
  ];
}

