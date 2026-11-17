import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/queue_ticket.dart';
import '../providers/queue_provider.dart';

/// 09. `menu inicial - atendimento do paciente` (Node `11:479` no Figma).
class PatientCallScreen extends ConsumerWidget {
  const PatientCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final ticket =
        queueState.selectedCallTicket ?? queueState.tickets.first;
    final notifier = ref.read(queueProvider.notifier);

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
                const Text('Chamar Paciente', style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                SectionCard(
                  children: [
                    // Banner Painel da TV da UBS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.azulProfundo,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CHAMANDO NO PAINEL DA UBS',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.azulClaro,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ticket.positionBadge} • ${ticket.room}',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.branco,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tempo em atendimento: 04m 12s',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.verdeClaro,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Ficha do Paciente',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    _FichaRow(label: 'Nome:', value: ticket.patientName),
                    _FichaRow(
                      label: 'Idade / CPF:',
                      value: '${ticket.age} anos • ${ticket.cpf}',
                    ),
                    _FichaRow(label: 'Cartão SUS:', value: ticket.susCard),
                    _FichaRow(
                      label: 'Prioridade Legal:',
                      value: ticket.priorityLabel,
                    ),
                    _FichaRow(
                      label: 'Especialidade:',
                      value: '${ticket.specialty} • ${ticket.doctorName}',
                    ),
                    _FichaRow(
                      label: 'Triagem / Notas:',
                      value: ticket.triageNotes,
                    ),
                    const SizedBox(height: 4),
                    FilaFacilButton(
                      label: 'Concluir Atendimento',
                      variant: FilaFacilButtonVariant.success,
                      width: 290,
                      onPressed: () async {
                        await notifier.updateStatus(
                          ticket.id,
                          QueueStatus.completed,
                        );
                        if (context.mounted) {
                          context.pop();
                        }
                      },
                    ),
                    FilaFacilButton(
                      label: 'Chamar Novamente no Painel',
                      width: 290,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Chamando ${ticket.patientName} (${ticket.positionBadge}) novamente no painel da ${ticket.room}!',
                            ),
                          ),
                        );
                      },
                    ),
                    FilaFacilButton(
                      label: 'Marcar como Não Compareceu',
                      variant: FilaFacilButtonVariant.dangerOutline,
                      width: 290,
                      height: 44,
                      onPressed: () async {
                        await notifier.updateStatus(
                          ticket.id,
                          QueueStatus.absent,
                        );
                        if (context.mounted) {
                          context.pop();
                        }
                      },
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

class _FichaRow extends StatelessWidget {
  const _FichaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyRegular),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.azulUbs,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
