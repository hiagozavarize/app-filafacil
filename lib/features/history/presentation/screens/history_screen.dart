import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../queue/domain/entities/queue_ticket.dart';
import '../../../queue/presentation/providers/queue_provider.dart';

/// 11. `menu inicial - histórico` (Node `6:420` no Figma).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const List<String> _filters = <String>[
    'Todos',
    'Concluídos',
    'Ausentes',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final notifier = ref.read(queueProvider.notifier);
    final historyRecords = queueState.historyFilteredTickets;

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
                const Text('Histórico', style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                // Card 1: Filtrar Registros
                SectionCard(
                  title: 'Filtrar Registros',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.azulClaro),
                      ),
                      child: TextField(
                        onChanged: notifier.setHistorySearchQuery,
                        style: AppTextStyles.bodyRegular,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.azulUbs,
                            size: 20,
                          ),
                          hintText: 'Buscar paciente, CPF ou protocolo...',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected =
                              queueState.historyFilter == filter;
                          final label = filter == 'Todos'
                              ? 'Todos (148)'
                              : filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: () => notifier.setHistoryFilter(filter),
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
                // Card 2: Atendimentos Recentes (`item historico` instances)
                SectionCard(
                  title: 'Atendimentos Recentes',
                  children: [
                    if (historyRecords.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nenhum registro encontrado.',
                          style: AppTextStyles.bodyRegular,
                        ),
                      )
                    else
                      ...historyRecords.map(
                        (record) => _HistoryRecordItem(ticket: record),
                      ),
                    const SizedBox(height: 4),
                    FilaFacilButton(
                      label: 'Ver Mais Registros',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Todos os registros recentes já estão carregados.',
                            ),
                          ),
                        );
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

/// Componente `item historico` (`2:56` no Figma).
class _HistoryRecordItem extends StatelessWidget {
  const _HistoryRecordItem({required this.ticket});

  final QueueTicket ticket;

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg) = switch (ticket.status) {
      QueueStatus.completed => (AppColors.verdeClaro, AppColors.verdeSucesso),
      QueueStatus.absent => (AppColors.cinzaClaro, AppColors.vermelho),
      _ => (AppColors.cinzaClaro, AppColors.cinzaEscuro),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.azulClaro, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  ticket.patientName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  ticket.status.label,
                  style: AppTextStyles.caption.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${ticket.specialty} • ${ticket.ubsName} (${ticket.room})',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.azulUbs,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ticket.scheduledDate} às ${ticket.scheduledTime} • Prot. ${ticket.protocol}',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

