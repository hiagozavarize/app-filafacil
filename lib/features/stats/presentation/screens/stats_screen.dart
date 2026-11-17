import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/ubs_select_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../queue/presentation/providers/queue_provider.dart';

/// 10. `menu inicial - estatísticas` (Node `6:308` no Figma).
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedPeriod = 'Últimos 7 dias';

  static const List<String> _periods = <String>[
    'Hoje',
    'Últimos 7 dias',
    'Novembro 2026',
  ];

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
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
                const Text('Estatísticas', style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                // Card 1: Visão Geral da Unidade + KPIs
                SectionCard(
                  title: 'Visão Geral da Unidade',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UbsSelectField(
                      selectedUbs: queueState.selectedUbs,
                      onChanged: notifier.setSelectedUbs,
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _periods.map((period) {
                          final isSelected = period == _selectedPeriod;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: () =>
                                  setState(() => _selectedPeriod = period),
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
                                  period,
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
                    // Grid 2x2 de `card metrica`
                    Row(
                      children: [
                        const Expanded(
                          child: _KpiMetricCard(
                            title: 'Total Atendidos',
                            value: '148',
                            subtitle: '+12% vs semana ant.',
                            valueColor: AppColors.azulUbs,
                            subtitleColor: AppColors.verdeSucesso,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiMetricCard(
                            title: 'Na Fila Agora',
                            value: '${queueState.waitingCount + queueState.inAttendanceCount}',
                            subtitle:
                                '${queueState.inAttendanceCount} em atendimento',
                            valueColor: AppColors.azulProfundo,
                            subtitleColor: AppColors.azulUbs,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Expanded(
                          child: _KpiMetricCard(
                            title: 'Espera Média',
                            value: '18 min',
                            subtitle: 'Meta: < 25 min',
                            valueColor: AppColors.verdeSaude,
                            subtitleColor: AppColors.verdeSucesso,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _KpiMetricCard(
                            title: 'Taxa Ausência',
                            value: '6,4%',
                            subtitle: '9 não compareceram',
                            valueColor: AppColors.vermelho,
                            subtitleColor: AppColors.vermelho,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card 2: Por Especialidade
                const SectionCard(
                  title: 'Por Especialidade',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SpecialtyProgressBar(
                      name: 'Clínico Geral',
                      countLabel: '62 atend. (42%)',
                      fraction: 0.42,
                      color: AppColors.azulUbs,
                    ),
                    _SpecialtyProgressBar(
                      name: 'Pediatra',
                      countLabel: '36 atend. (24%)',
                      fraction: 0.24,
                      color: AppColors.azulClaro,
                    ),
                    _SpecialtyProgressBar(
                      name: 'Dentista',
                      countLabel: '30 atend. (20%)',
                      fraction: 0.20,
                      color: AppColors.verdeSaude,
                    ),
                    _SpecialtyProgressBar(
                      name: 'Ginecologista',
                      countLabel: '20 atend. (14%)',
                      fraction: 0.14,
                      color: AppColors.azulProfundo,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card 3: Fluxo por Horário
                SectionCard(
                  title: 'Fluxo por Horário',
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _HourlyBar(hour: '07h', count: 18, height: 48),
                          _HourlyBar(
                            hour: '08h',
                            count: 34,
                            height: 92,
                            isPeak: true,
                          ),
                          _HourlyBar(
                            hour: '09h',
                            count: 31,
                            height: 84,
                            isPeak: true,
                          ),
                          _HourlyBar(hour: '10h', count: 22, height: 60),
                          _HourlyBar(hour: '11h', count: 14, height: 38),
                          _HourlyBar(hour: '14h', count: 19, height: 52),
                          _HourlyBar(hour: '15h', count: 10, height: 28),
                        ],
                      ),
                    ),
                    FilaFacilButton(
                      label: 'Exportar Relatório',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Relatório de ${queueState.selectedUbs} ($_selectedPeriod) exportado com sucesso!',
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
