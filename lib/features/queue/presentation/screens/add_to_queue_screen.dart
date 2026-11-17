import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/filafacil_text_field.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/success_dialog.dart';
import '../../../../core/widgets/ubs_select_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/queue_provider.dart';

/// 06. `menu inicial - adicionar na fila` (Node `11:247` / `92:43` no Figma).
class AddToQueueScreen extends ConsumerStatefulWidget {
  const AddToQueueScreen({super.key});

  @override
  ConsumerState<AddToQueueScreen> createState() => _AddToQueueScreenState();
}

class _AddToQueueScreenState extends ConsumerState<AddToQueueScreen> {
  final _nameController = TextEditingController(text: 'Hiago Zavarize');
  final _cpfController = TextEditingController(text: '412.890.123-00');
  final _birthController = TextEditingController(text: '10/04/1999');

  String _selectedSpecialty = 'Clínico Geral';
  int _selectedDay = 19;
  String _selectedUbs = 'UBS Centro';
  String _selectedTime = '07:00';
  bool _isSubmitting = false;

  static const List<String> _specialties = <String>[
    'Clínico Geral',
    'Pediatra',
    'Ginecologista',
    'Dentista',
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
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);
    final dateLabel = '$_selectedDay Nov 2026';

    await ref
        .read(queueProvider.notifier)
        .addPatientToQueue(
          patientName: _nameController.text,
          cpf: _cpfController.text,
          birthDate: _birthController.text,
          specialty: _selectedSpecialty,
          ubsName: _selectedUbs,
          scheduledDate: dateLabel,
          scheduledTime: _selectedTime,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await SuccessDialog.show(context, message: 'Adicionado com sucesso!');

    if (mounted) {
      context.pushReplacement('/ticket-receipt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(authProvider).agent;
    final room = switch (_selectedSpecialty) {
      'Pediatra' => 'Sala 04',
      'Ginecologista' => 'Sala 03',
      'Dentista' => 'Sala 01',
      _ => 'Sala 02',
    };

    return Scaffold(
      appBar: FilaFacilHeader(agentName: agent.name, agentRole: agent.role),
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
                // Card 1: Dados do Paciente
                SectionCard(
                  title: 'Dados do Paciente',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormQuestionField(
                      label: 'Nome Completo',
                      hintText: 'ex: José Maria da Silva',
                      controller: _nameController,
                    ),
                    FormQuestionField(
                      label: 'CPF',
                      hintText: 'ex: 000.000.000-00',
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                    ),
                    FormQuestionField(
                      label: 'Data de Nascimento',
                      hintText: 'ex: dd/mm/aaaa',
                      controller: _birthController,
                      keyboardType: TextInputType.datetime,
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
                // Card 3: Data (Calendário Novembro 2026)
                SectionCard(
                  title: 'Data',
                  children: [
                    _NovemberCalendarWidget(
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
                      value: _nameController.text.isEmpty
                          ? 'Hiago Zavarize'
                          : _nameController.text,
                    ),
                    _SummaryRow(
                      label: 'Especialidade:',
                      value: _selectedSpecialty,
                      valueColor: AppColors.azulUbs,
                    ),
                    _SummaryRow(
                      label: 'Data:',
                      value: '$_selectedDay Nov 2026',
                    ),
                    _SummaryRow(label: 'Horário:', value: _selectedTime),
                    _SummaryRow(
                      label: 'Local:',
                      value: '$_selectedUbs • $room',
                    ),
                    const SizedBox(height: 6),
                    FilaFacilButton(
                      label: 'Fazer Registro',
                      isLoading: _isSubmitting,
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

class _NovemberCalendarWidget extends StatelessWidget {
  const _NovemberCalendarWidget({
    required this.selectedDay,
    required this.onSelectDay,
  });

  final int selectedDay;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    const weekdays = <String>['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
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
                'Novembro 2026',
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
