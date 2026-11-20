import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/ubs_select_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../queue/domain/entities/queue_ticket.dart';
import '../../../queue/presentation/providers/queue_provider.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../providers/stats_provider.dart';

/// 10. `menu inicial - estatísticas` (Node `6:308` no Figma).
/// Integrada a `/api/stats/dashboard`, `/api/stats/reports` e `/api/stats/export`.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(statsProvider.notifier).loadStats();
    });
  }

  Future<void> _handleExport() async {
    final csv = await ref.read(statsProvider.notifier).exportCsv();
    if (!mounted) return;
    if (csv != null) {
      final lineCount = csv
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Relatório CSV gerado pela API ($lineCount linha(s) exportadas)!',
          ),
          backgroundColor: AppColors.verdeSaude,
        ),
      );
    } else {
      final error = ref.read(statsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Não foi possível exportar o relatório.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  List<SpecialtyMetric> _buildBreakdown(DashboardStats stats) {
    if (stats.bySpecialty.isNotEmpty) return stats.bySpecialty;
    if (stats.byPriority.isEmpty) return const <SpecialtyMetric>[];
    final total = stats.byPriority.values.fold<int>(0, (a, b) => a + b);
    final entries = stats.byPriority.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) {
      final priority = TicketPriority.fromApi(e.key);
      return SpecialtyMetric(
        name: priority.shortLabel,
        count: e.value,
        fraction: total > 0 ? e.value / total : 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final queueNotifier = ref.read(queueProvider.notifier);
    final statsState = ref.watch(statsProvider);
    final statsNotifier = ref.read(statsProvider.notifier);
    final stats = statsState.stats;

    final breakdown = _buildBreakdown(stats);
    const barColors = <Color>[
      AppColors.azulUbs,
      AppColors.azulClaro,
      AppColors.verdeSaude,
      AppColors.azulProfundo,
    ];

    final maxHourly = stats.hourlyFlow.isEmpty
        ? 1
        : stats.hourlyFlow
              .map((p) => p.count)
              .reduce((a, b) => a > b ? a : b)
              .clamp(1, 999999);

    return Scaffold(
      appBar: FilaFacilHeader(
        agentName: agent.name,
        agentRole: agent.roleDisplayLabel,
      ),
      body: RefreshIndicator(
        onRefresh: () => statsNotifier.loadStats(),
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
                  const Text('Estatísticas', style: AppTextStyles.pageTitle),
                  const SizedBox(height: 18),
                  if (statsState.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.vermelho.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.vermelho.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.vermelho,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              statsState.errorMessage!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.vermelho,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => statsNotifier.loadStats(),
                            child: const Text('Tentar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Card 1: Visão Geral da Unidade + KPIs
                  SectionCard(
                    title: 'Visão Geral da Unidade',
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UbsSelectField(
                        selectedUbs: queueState.selectedUbs,
                        onChanged: queueNotifier.setSelectedUbs,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: StatsPeriod.values.map((period) {
                            final isSelected = period == statsState.period;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(99),
                                onTap: () =>
                                    statsNotifier.loadStats(period: period),
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
                                    period.label,
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
                      if (statsState.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.azulUbs,
                            ),
                          ),
                        )
                      else ...[
                        // Grid 2x2 de `card metrica`
                        Row(
                          children: [
                            Expanded(
                              child: _KpiMetricCard(
                                title: 'Total Atendidos',
                                value: '${stats.finishedCount}',
                                subtitle:
                                    'Meta SUS: ${stats.withinSusGoalPercentage.toStringAsFixed(1)}%',
                                valueColor: AppColors.azulUbs,
                                subtitleColor: AppColors.verdeSucesso,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiMetricCard(
                                title: 'Na Fila Agora',
                                value: '${stats.activeNowCount}',
                                subtitle:
                                    '${stats.inProgressCount} em atendimento',
                                valueColor: AppColors.azulProfundo,
                                subtitleColor: AppColors.azulUbs,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _KpiMetricCard(
                                title: 'Espera Média',
                                value:
                                    '${stats.averageWaitTimeMinutes.toStringAsFixed(0)} min',
                                subtitle: 'Meta SUS: ≤ 20 min',
                                valueColor: AppColors.verdeSaude,
                                subtitleColor: AppColors.verdeSucesso,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiMetricCard(
                                title: 'Taxa Ausência',
                                value:
                                    '${stats.absenceRatePercentage.toStringAsFixed(1).replaceAll('.', ',')}%',
                                subtitle:
                                    '${stats.absentCount} não compareceram',
                                valueColor: AppColors.vermelho,
                                subtitleColor: AppColors.vermelho,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Card 2: Por Especialidade ou Prioridade
                  SectionCard(
                    title: stats.bySpecialty.isNotEmpty
                        ? 'Por Especialidade'
                        : 'Por Prioridade SUS',
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: breakdown.isEmpty
                        ? [
                            Text(
                              'Sem dados distribuídos para o período selecionado.',
                              style: AppTextStyles.bodyRegular,
                            ),
                          ]
                        : breakdown.asMap().entries.map((entry) {
                            final item = entry.value;
                            final pct = (item.fraction * 100).round();
                            return _SpecialtyProgressBar(
                              name: item.name,
                              countLabel: '${item.count} atend. ($pct%)',
                              fraction: item.fraction.clamp(0.0, 1.0),
                              color: barColors[entry.key % barColors.length],
                            );
                          }).toList(),
                  ),
                  const SizedBox(height: 18),
                  // Card 3: Fluxo por Horário + Exportação
                  SectionCard(
                    title: 'Fluxo por Horário',
                    children: [
                      if (stats.hourlyFlow.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                          decoration: BoxDecoration(
                            color: AppColors.branco,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: stats.hourlyFlow.take(7).map((point) {
                              final barHeight =
                                  16.0 + (point.count / maxHourly) * 76.0;
                              final isPeak = point.count >= maxHourly * 0.85;
                              return _HourlyBar(
                                hour: point.hour,
                                count: point.count,
                                height: barHeight,
                                isPeak: isPeak,
                              );
                            }).toList(),
                          ),
                        )
                      else
                        Text(
                          'O fluxo por horário será exibido conforme novos atendimentos forem registrados.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      FilaFacilButton(
                        label: 'Exportar Relatório (CSV)',
                        isLoading: statsState.isExporting,
                        onPressed: _handleExport,
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

/// Componente `card metrica` (`2:52` no Figma).
class _KpiMetricCard extends StatelessWidget {
  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    required this.subtitleColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.azulClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyProgressBar extends StatelessWidget {
  const _SpecialtyProgressBar({
    required this.name,
    required this.countLabel,
    required this.fraction,
    required this.color,
  });

  final String name;
  final String countLabel;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              countLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.azulUbs,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: AppColors.branco,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _HourlyBar extends StatelessWidget {
  const _HourlyBar({
    required this.hour,
    required this.count,
    required this.height,
    this.isPeak = false,
  });

  final String hour;
  final int count;
  final double height;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isPeak ? AppColors.azulUbs : AppColors.cinzaEscuro,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 26,
          height: height,
          decoration: BoxDecoration(
            color: isPeak ? AppColors.azulUbs : AppColors.azulClaro,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(hour, style: AppTextStyles.caption),
      ],
    );
  }
}
