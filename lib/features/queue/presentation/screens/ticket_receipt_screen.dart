import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/queue_provider.dart';

/// 07. `menu inicial - comprovante de agendamento` (Node `11:433` no Figma).
class TicketReceiptScreen extends ConsumerWidget {
  const TicketReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final ticket =
        queueState.latestCreatedTicket ?? queueState.tickets.first;

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
                const Text('Senha Gerada', style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                SectionCard(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verdeClaro,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '✓ Agendamento Confirmado na Fila',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.verdeSucesso,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.azulUbs,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'SENHA DE ATENDIMENTO',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.cinzaClaro,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.ticketCode,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.branco,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ticket.positionNumber}º da fila • Previsão: ~${ticket.scheduledTime}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.verdeClaro,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TicketInfoRow(
                      label: 'Paciente',
                      value: ticket.patientName,
                    ),
                    _TicketInfoRow(label: 'CPF', value: ticket.cpf),
                    _TicketInfoRow(
                      label: 'Especialidade',
                      value: '${ticket.specialty} • ${ticket.room}',
                    ),
                    _TicketInfoRow(label: 'Unidade', value: ticket.ubsName),
                    _TicketInfoRow(
                      label: 'Data e Hora',
                      value:
                          '${ticket.scheduledDate} às ${ticket.scheduledTime}',
                    ),
                    _TicketInfoRow(
                      label: 'Protocolo SUS',
                      value: ticket.protocol,
                    ),
                    const SizedBox(height: 4),
                    FilaFacilButton(
                      label: 'Enviar via WhatsApp / SMS',
                      variant: FilaFacilButtonVariant.success,
                      width: 290,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Comprovante ${ticket.ticketCode} enviado para ${ticket.patientName}!',
                            ),
                          ),
                        );
                      },
                    ),
                    FilaFacilButton(
                      label: 'Voltar ao Menu Inicial',
                      width: 290,
                      onPressed: () => context.go('/home'),
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

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyRegular),
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
