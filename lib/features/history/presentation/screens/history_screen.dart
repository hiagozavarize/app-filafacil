import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../queue/domain/entities/queue_ticket.dart';
import '../providers/history_provider.dart';

/// 11. `menu inicial - histórico` (Node `6:420` no Figma).
/// Integrada a `/api/history`, `/api/history/{id}` e `/api/history/export`.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const List<String> _filters = <String>[
    'Todos',
    'Concluídos',
    'Ausentes',
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(historyProvider.notifier).loadHistory();
    });
  }

  Future<void> _openAuditDetail(QueueTicket record) async {
    final detailed =
        await ref.read(historyProvider.notifier).fetchAuditDetail(record.id) ??
        record;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auditoria • ${detailed.ticketCode}',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              _AuditRow(label: 'Paciente', value: detailed.patientName),
              if (detailed.cpf.isNotEmpty)
                _AuditRow(label: 'CPF', value: detailed.cpf),
              _AuditRow(label: 'Status', value: detailed.status.label),
              _AuditRow(
                label: 'Especialidade',
                value: '${detailed.specialty} • ${detailed.room}',
              ),
              _AuditRow(label: 'Profissional', value: detailed.doctorName),
              if (detailed.waitTimeMinutes != null)
                _AuditRow(
                  label: 'Tempo de Espera',
                  value: '${detailed.waitTimeMinutes} min',
                ),
              if (detailed.serviceDurationMinutes != null)
                _AuditRow(
                  label: 'Duração da Consulta',
                  value: '${detailed.serviceDurationMinutes} min',
                ),
              if (detailed.cid10 != null && detailed.cid10!.isNotEmpty)
                _AuditRow(label: 'CID-10', value: detailed.cid10!),
              _AuditRow(label: 'Notas', value: detailed.triageNotes),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleExportCsv() async {
    final csv = await ref.read(historyProvider.notifier).exportCsv();
    if (!mounted) return;
    if (csv != null) {
      final lineCount = csv
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Histórico CSV exportado pela API ($lineCount linha(s))!',
          ),
          backgroundColor: AppColors.verdeSaude,
        ),
      );
    } else {
      final error = ref.read(historyProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Não foi possível exportar o histórico.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(authProvider).agent;
    final historyState = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);
    final historyRecords = historyState.filteredRecords;

    return Scaffold(
      appBar: FilaFacilHeader(
        agentName: agent.name,
        agentRole: agent.roleDisplayLabel,
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadHistory(),
        color: AppColors.azulUbs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          onChanged: notifier.setSearchQuery,
                          onSubmitted: (value) =>
                              notifier.loadHistory(search: value),
                          style: AppTextStyles.bodyRegular,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.azulUbs,
                              size: 20,
                            ),
                            hintText: 'Buscar paciente, CPF ou senha...',
                            hintStyle: AppTextStyles.bodyRegular.copyWith(
                              color: AppColors.cinzaEscuro.withValues(
                                alpha: 0.6,
                              ),
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
                                historyState.selectedFilter == filter;
                            final label = filter == 'Todos'
                                ? 'Todos (${historyState.records.length})'
                                : filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(99),
                                onTap: () => notifier.setFilter(filter),
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
                  // Card 2: Atendimentos Recentes
                  SectionCard(
                    title: 'Atendimentos Recentes',
                    children: [
                      if (historyState.isLoading && historyRecords.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.azulUbs,
                          ),
                        )
                      else if (historyState.errorMessage != null &&
                          historyRecords.isEmpty)
                        Column(
                          children: [
                            Text(
                              historyState.errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyRegular.copyWith(
                                color: AppColors.vermelho,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => notifier.loadHistory(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        )
                      else if (historyRecords.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Nenhum registro encontrado.',
                            style: AppTextStyles.bodyRegular,
                          ),
                        )
                      else
                        ...historyRecords.map(
                          (record) => _HistoryRecordItem(
                            ticket: record,
                            onTap: () => _openAuditDetail(record),
                          ),
                        ),
                      const SizedBox(height: 4),
                      FilaFacilButton(
                        label: 'Exportar Histórico (CSV)',
                        isLoading: historyState.isExporting,
                        onPressed: _handleExportCsv,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Componente `item historico` (`2:56` no Figma).
class _HistoryRecordItem extends StatelessWidget {
  const _HistoryRecordItem({required this.ticket, required this.onTap});

  final QueueTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg) = switch (ticket.status) {
      QueueStatus.completed => (AppColors.verdeClaro, AppColors.verdeSucesso),
      QueueStatus.absent => (AppColors.cinzaClaro, AppColors.vermelho),
      _ => (AppColors.cinzaClaro, AppColors.cinzaEscuro),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
              '${ticket.specialty} • ${ticket.room}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.azulUbs,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${ticket.scheduledDate} às ${ticket.scheduledTime} • ${ticket.protocol}',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyRegular),
          const SizedBox(width: 12),
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
      ),
    );
  }
}
