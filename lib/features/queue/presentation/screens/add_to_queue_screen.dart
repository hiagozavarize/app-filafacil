import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/filafacil_text_field.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/success_dialog.dart';
import '../../../../core/widgets/ubs_select_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/queue_ticket.dart';
import '../providers/queue_provider.dart';

/// 06. `menu inicial - adicionar na fila` (Node `11:247` / `92:43` no Figma).
/// Integrada a `GET /api/patients/search` e `POST /api/tickets`.
class AddToQueueScreen extends ConsumerStatefulWidget {
  const AddToQueueScreen({super.key});

  @override
  ConsumerState<AddToQueueScreen> createState() => _AddToQueueScreenState();
}

class _AddToQueueScreenState extends ConsumerState<AddToQueueScreen> {
  final _cadsusSearchController = TextEditingController();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _susCardController = TextEditingController();
  final _birthController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  String _selectedSpecialty = 'Clínica Geral';
  TicketPriority _selectedPriority = TicketPriority.normal;
  int _selectedDay = DateTime.now().day.clamp(1, 28);
  late String _selectedUbs;
  String _selectedTime = '08:00';
  bool _isSearchingCadsus = false;
  List<Patient> _cadsusResults = const <Patient>[];

  static const List<String> _specialties = <String>[
    'Clínica Geral',
    'Pediatria',
    'Ginecologia',
    'Odontologia',
  ];

  static const List<String> _timeSlots = <String>[
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '14:00',
    '14:30',
    '15:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedUbs = ref.read(authProvider).agent.assignedUbs;
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cadsusSearchController.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    _susCardController.dispose();
    _birthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchCadsus() async {
    final query = _cadsusSearchController.text.trim();
    if (query.length < 2) {
      setState(() => _cadsusResults = const <Patient>[]);
      return;
    }
    setState(() => _isSearchingCadsus = true);
    final results = await ref
        .read(queueProvider.notifier)
        .searchPatients(query);
    if (!mounted) return;
    setState(() {
      _isSearchingCadsus = false;
      _cadsusResults = results;
    });
  }

  void _applyPatientFromCadsus(Patient patient) {
    setState(() {
      _selectedPatientId = patient.id.isNotEmpty ? patient.id : null;
      _nameController.text = patient.name;
      _cpfController.text = formatCpf(patient.cpf);
      _susCardController.text = formatSusCard(patient.cartaoSus);
      _birthController.text = formatBirthDateToBr(patient.birthDate);
      _selectedPriority = TicketPriority.fromApi(patient.priorityGroup);
      if (patient.conditions.isNotEmpty &&
          _notesController.text.trim().isEmpty) {
        _notesController.text =
            'Condições CADSUS: ${patient.conditions.join(', ')}';
      }
      _cadsusResults = const <Patient>[];
    });
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome completo do paciente.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    final cpfDigits = digitsOnly(_cpfController.text);
    if (cpfDigits.isNotEmpty && cpfDigits.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CPF incompleto. Informe os 11 dígitos (000.000.000-00).'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    final rawBirth = _birthController.text.trim();
    if (rawBirth.isNotEmpty && formatBirthDateToIso(rawBirth) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data de nascimento inválida. Use o formato dd/mm/aaaa.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    final now = DateTime.now();
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
    final dateLabel =
        '${_selectedDay.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
    final scheduledDateIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';

    final created = await ref
        .read(queueProvider.notifier)
        .addPatientToQueue(
          patientId: _selectedPatientId,
          patientName: _nameController.text,
          cpf: _cpfController.text,
          susCard: _susCardController.text,
          birthDate: rawBirth,
          specialty: _selectedSpecialty,
          ubsName: _selectedUbs,
          scheduledDate: dateLabel,
          scheduledDateIso: scheduledDateIso,
          scheduledTime: _selectedTime,
          priority: _selectedPriority,
          notes: _notesController.text,
        );

    if (!mounted) return;

    if (created == null) {
      final error = ref.read(queueProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Não foi possível emitir a senha.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    await SuccessDialog.show(context, message: 'Adicionado com sucesso!');

    if (mounted) {
      context.pushReplacement('/ticket-receipt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final room = switch (_selectedSpecialty) {
      'Pediatria' => 'Consultorio 04',
      'Ginecologia' => 'Consultorio 03',
      'Odontologia' => 'Consultorio 02',
      _ => 'Consultorio 01',
    };

    return Scaffold(
      appBar: FilaFacilHeader(
        agentName: agent.name,
        agentRole: agent.roleDisplayLabel,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(23, 20, 24, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adicionar na Fila', style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                // Card 1: Dados do Paciente + Busca CADSUS
                SectionCard(
                  title: 'Dados do Paciente',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.azulClaro),
                      ),
                      child: TextField(
                        controller: _cadsusSearchController,
                        onSubmitted: (_) => _searchCadsus(),
                        style: AppTextStyles.bodyRegular,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person_search_rounded,
                            color: AppColors.azulUbs,
                            size: 20,
                          ),
                          suffixIcon: _isSearchingCadsus
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.azulUbs,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.azulUbs,
                                    size: 20,
                                  ),
                                  onPressed: _searchCadsus,
                                ),
                          hintText: 'Buscar no CADSUS por nome, CPF ou CNS...',
                          hintStyle: AppTextStyles.caption.copyWith(
                            color: AppColors.cinzaEscuro.withValues(alpha: 0.6),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_cadsusResults.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.branco,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.azulClaro),
                        ),
                        child: Column(
                          children: _cadsusResults.take(4).map((p) {
                            return ListTile(
                              dense: true,
                              title: Text(
                                p.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'CPF: ${p.cpf} • CNS: ${p.cartaoSus}',
                                style: AppTextStyles.caption,
                              ),
                              trailing: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.azulUbs,
                                size: 20,
                              ),
                              onTap: () => _applyPatientFromCadsus(p),
                            );
                          }).toList(),
                        ),
                      ),
                    FormQuestionField(
                      label: 'Nome Completo',
                      hintText: 'ex: Benedita Souza Costa',
                      controller: _nameController,
                    ),
                    FormQuestionField(
                      label: 'CPF',
                      hintText: 'ex: 000.000.000-00',
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [CpfInputFormatter()],
                    ),
                    FormQuestionField(
                      label: 'Cartão SUS (CNS)',
                      hintText: 'ex: 892 4410 2981 0001',
                      controller: _susCardController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [SusCardInputFormatter()],
                    ),
                    FormQuestionField(
                      label: 'Data de Nascimento',
                      hintText: 'ex: dd/mm/aaaa',
                      controller: _birthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [DateBrInputFormatter()],
                    ),
                    FormQuestionField(
                      label: 'Observações / Triagem',
                      hintText: 'Queixa principal ou nota de acolhimento',
                      controller: _notesController,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Prioridade Legal do SUS
                SectionCard(
                  title: 'Prioridade Legal (SUS)',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: TicketPriority.values.map((priority) {
                        final isSelected = priority == _selectedPriority;
                        return InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () =>
                              setState(() => _selectedPriority = priority),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.azulUbs
                                  : AppColors.branco,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.azulUbs
                                    : AppColors.azulClaro,
                              ),
                            ),
                            child: Text(
                              priority.shortLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? AppColors.branco
                                    : AppColors.azulUbs,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card 2: Especialidade
                SectionCard(
                  title: 'Especialidade',
                  children: _specialties.map((spec) {
                    final isSelected = spec == _selectedSpecialty;
                    return SizedBox(
                      width: 290,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _selectedSpecialty = spec),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? AppColors.azulUbs
                              : AppColors.azulClaro,
                          foregroundColor: AppColors.branco,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          spec,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.branco,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                // Card 3: Data
                SectionCard(
                  title: 'Data',
                  children: [
                    _MonthCalendarWidget(
                      selectedDay: _selectedDay,
                      onSelectDay: (d) => setState(() => _selectedDay = d),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card 4: Local
                SectionCard(
                  title: 'Local',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UbsSelectField(
                      selectedUbs: _selectedUbs,
                      onChanged: (ubs) => setState(() => _selectedUbs = ubs),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card 5: Horário
                SectionCard(
                  title: 'Horário',
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _timeSlots.map((slot) {
                        final isSelected = slot == _selectedTime;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _selectedTime = slot),
                          child: Container(
                            width: 98,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.azulUbs
                                  : AppColors.branco,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.azulUbs
                                    : AppColors.azulClaro,
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              slot,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 15,
                                color: isSelected
                                    ? AppColors.branco
                                    : AppColors.cinzaEscuro,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card 6: Resumo
                SectionCard(
                  title: 'Resumo',
                  children: [
                    _SummaryRow(
                      label: 'Paciente:',
                      value: _nameController.text.trim().isEmpty
                          ? 'Não informado'
                          : _nameController.text.trim(),
                    ),
                    _SummaryRow(
                      label: 'Prioridade:',
                      value: _selectedPriority.shortLabel,
                      valueColor: AppColors.azulProfundo,
                    ),
                    _SummaryRow(
                      label: 'Especialidade:',
                      value: _selectedSpecialty,
                      valueColor: AppColors.azulUbs,
                    ),
                    _SummaryRow(label: 'Horário:', value: _selectedTime),
                    _SummaryRow(
                      label: 'Local:',
                      value: '$_selectedUbs • $room',
                    ),
                    const SizedBox(height: 6),
                    FilaFacilButton(
                      label: 'Emitir Senha na Fila',
                      isLoading: queueState.isActionLoading,
                      onPressed: _submitRegistration,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.cinzaEscuro,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 15,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthCalendarWidget extends StatelessWidget {
  const _MonthCalendarWidget({
    required this.selectedDay,
    required this.onSelectDay,
  });

  final int selectedDay;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    const weekdays = <String>['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    const monthNames = <String>[
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    final now = DateTime.now();
    final days = List<int>.generate(28, (i) => i + 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.azulClaro),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '‹',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulUbs,
                ),
              ),
              Text(
                '${monthNames[now.month - 1]} ${now.year}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                '›',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulUbs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map(
                  (w) => SizedBox(
                    width: 34,
                    child: Center(
                      child: Text(
                        w,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.azulUbs,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = day == selectedDay;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelectDay(day),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.azulUbs : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$day',
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: isSelected
                          ? AppColors.branco
                          : AppColors.cinzaEscuro,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
