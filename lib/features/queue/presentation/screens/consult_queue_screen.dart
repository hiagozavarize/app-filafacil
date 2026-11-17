import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/ubs_select_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/queue_ticket.dart';
import '../providers/queue_provider.dart';

/// 08. `menu inicial - consultar fila` (Node `6:193` no Figma).
class ConsultQueueScreen extends ConsumerWidget {
  const ConsultQueueScreen({super.key});

  static const List<String> _filterPills = <String>[
    'Todos',
    'Clínico',
    'Pediatra',
    'Dentista',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final notifier = ref.read(queueProvider.notifier);
    final activeTickets = queueState.activeFilteredTickets;

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
                const Text('Consultar Fila', style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                // Card 1: Unidade e Especialidade
                SectionCard(
                  title: 'Unidade e Especialidade',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UbsSelectField(
                      selectedUbs: queueState.selectedUbs,
                      onChanged: notifier.setSelectedUbs,
                    ),
                    // Barra de busca
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.azulClaro),
                      ),
                      child: TextField(
                        onChanged: notifier.setSearchQuery,
                        style: AppTextStyles.bodyRegular,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.azulUbs,
                            size: 20,
                          ),
                          hintText: 'Buscar paciente por nome ou CPF...',
                          hintStyle: AppTextStyles.bodyRegular.copyWith(
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
                    // Pílulas de especialidade
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterPills.map((pill) {
                          final isSelected =
                              queueState.selectedSpecialty == pill;
                          final label = pill == 'Todos'
                              ? 'Todos (${queueState.waitingCount + queueState.inAttendanceCount})'
                              : pill;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: () => notifier.setSelectedSpecialty(pill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
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
                                  label,
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
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Resumo rápido da fila (3 mini cards)
                Row(
                  children: [
                    Expanded(
                      child: _QuickStatBadge(
                        value: queueState.waitingCount.toString().padLeft(
                          2,
                          '0',
                        ),
                        label: 'Aguardando',
                        valueColor: AppColors.azulUbs,
                        bgColor: AppColors.cinzaClaro,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickStatBadge(
                        value: queueState.inAttendanceCount.toString().padLeft(
                          2,
                          '0',
                        ),
                        label: 'Atendendo',
                        valueColor: AppColors.verdeSaude,
                        bgColor: AppColors.verdeClaro,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _QuickStatBadge(
                        value: '18m',
                        label: 'Espera Média',
                        valueColor: AppColors.azulProfundo,
                        bgColor: AppColors.cinzaClaro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card 2: Pacientes na Fila (`card paciente fila` instances)
                SectionCard(
                  title: 'Pacientes na Fila',
                  children: [
                    if (activeTickets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nenhum paciente aguardando para este filtro.',
                          style: AppTextStyles.bodyRegular,
                        ),
                      )
                    else
                      ...activeTickets.map(
                        (ticket) => _PatientQueueCard(
                          ticket: ticket,
                          onTapCard: () {
                            notifier.selectTicketForCall(ticket);
                            context.push('/patient-call');
                          },
                          onActionPressed: () {
                            if (ticket.status == QueueStatus.inAttendance) {
                              notifier.updateStatus(
                                ticket.id,
                                QueueStatus.completed,
                              );
                            } else {
                              notifier.selectTicketForCall(ticket);
                              notifier.updateStatus(
                                ticket.id,
                                QueueStatus.inAttendance,
                              );
                              context.push('/patient-call');
                            }
                          },
                        ),
                      ),
                    const SizedBox(height: 4),
                    FilaFacilButton(
                      label: 'Adicionar Paciente',
                      onPressed: () => context.push('/add-to-queue'),
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

class _QuickStatBadge extends StatelessWidget {
  const _QuickStatBadge({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.bgColor,
  });

  final String value;
  final String label;
  final Color valueColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.azulClaro, width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Componente `card paciente fila` (`2:37` no Figma).
class _PatientQueueCard extends StatelessWidget {
  const _PatientQueueCard({
    required this.ticket,
    required this.onTapCard,
    required this.onActionPressed,
  });

  final QueueTicket ticket;
  final VoidCallback onTapCard;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final isAttending = ticket.status == QueueStatus.inAttendance;
    final isNext = ticket.status == QueueStatus.next;

    final statusBg = isAttending
        ? AppColors.verdeClaro
        : AppColors.cinzaClaro;
    final statusFg = isAttending
        ? AppColors.verdeSaude
        : isNext
        ? AppColors.azulUbs
        : AppColors.azulProfundo;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTapCard,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.azulClaro),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.azulUbs,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ticket.positionBadge,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.branco,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          ticket.patientName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    ticket.status.label,
                    style: AppTextStyles.caption.copyWith(
                      color: statusFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ticket.specialty} • ${ticket.room}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.azulUbs,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${ticket.scheduledTime} • CPF ${ticket.cpf}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    ticket.priorityLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.azulProfundo,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onActionPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isAttending
                          ? AppColors.verdeSaude
                          : AppColors.azulUbs,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAttending ? 'Concluir' : 'Chamar',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.branco,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
