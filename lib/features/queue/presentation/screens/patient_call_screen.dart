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
/// Integrada a `/api/tickets/{id}/call`, `/start`, `/recall`, `/finish` e `/absent`.
class PatientCallScreen extends ConsumerStatefulWidget {
  const PatientCallScreen({super.key});

  @override
  ConsumerState<PatientCallScreen> createState() => _PatientCallScreenState();
}

class _PatientCallScreenState extends ConsumerState<PatientCallScreen> {
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.vermelho : AppColors.verdeSaude,
      ),
    );
  }

  Future<void> _handleFinishDialog(QueueTicket ticket) async {
    final result = await showDialog<({String cid10, String notes})>(
      context: context,
      builder: (_) => _FinishAttendanceDialog(
        initialCid10: ticket.cid10 ?? '',
        initialNotes: ticket.triageNotes,
      ),
    );

    if (result == null || !mounted) return;

    final ok = await ref
        .read(queueProvider.notifier)
        .finishAttendance(
          ticketId: ticket.id,
          cid10: result.cid10.isEmpty ? null : result.cid10,
          notes: result.notes.isEmpty ? null : result.notes,
        );

    if (!mounted) return;
    if (ok) {
      _showFeedback('Atendimento de ${ticket.patientName} finalizado!');
      context.pop();
    } else {
      _showFeedback(
        ref.read(queueProvider).errorMessage ??
            'Erro ao finalizar atendimento.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final ticket =
        queueState.selectedCallTicket ??
        (queueState.tickets.isNotEmpty ? queueState.tickets.first : null);
    final notifier = ref.read(queueProvider.notifier);

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
            child: ticket == null
                ? SectionCard(
                    title: 'Nenhum Paciente Selecionado',
                    children: [
                      const Text(
                        'Selecione uma senha na fila para gerenciar o atendimento.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyRegular,
                      ),
                      FilaFacilButton(
                        label: 'Voltar para a Fila',
                        onPressed: () => context.pop(),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atendimento do Paciente',
                        style: AppTextStyles.pageTitle,
                      ),
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
                                  ticket.status == QueueStatus.inAttendance
                                      ? 'EM ATENDIMENTO NO CONSULTÓRIO'
                                      : ticket.status == QueueStatus.called
                                      ? 'CHAMANDO NO PAINEL DA UBS'
                                      : 'AGUARDANDO CHAMADA NO PAINEL',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.azulClaro,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ticket.positionBadge} • ${ticket.room}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.branco,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${ticket.status.label} • Emitido às ${ticket.scheduledTime}',
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
                          if (ticket.cpf.isNotEmpty)
                            _FichaRow(
                              label: ticket.age > 0 ? 'Idade / CPF:' : 'CPF:',
                              value: ticket.age > 0
                                  ? '${ticket.age} anos • ${ticket.cpf}'
                                  : ticket.cpf,
                            ),
                          if (ticket.susCard.isNotEmpty)
                            _FichaRow(
                              label: 'Cartão SUS:',
                              value: ticket.susCard,
                            ),
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
                          if (ticket.status == QueueStatus.waiting ||
                              ticket.status == QueueStatus.next)
                            FilaFacilButton(
                              label: 'Chamar no Painel da TV',
                              width: 290,
                              isLoading: queueState.isActionLoading,
                              onPressed: () async {
                                final called = await notifier.callTicket(
                                  ticketId: ticket.id,
                                  roomName: ticket.room,
                                  doctorName: agent.name,
                                );
                                if (called != null) {
                                  _showFeedback(
                                    '${ticket.patientName} chamado(a) na ${ticket.room}!',
                                  );
                                } else {
                                  _showFeedback(
                                    ref.read(queueProvider).errorMessage ??
                                        'Erro ao chamar senha.',
                                    isError: true,
                                  );
                                }
                              },
                            ),
                          if (ticket.status == QueueStatus.called)
                            FilaFacilButton(
                              label: 'Iniciar Atendimento',
                              variant: FilaFacilButtonVariant.success,
                              width: 290,
                              isLoading: queueState.isActionLoading,
                              onPressed: () async {
                                final ok = await notifier.startAttendance(
                                  ticket.id,
                                );
                                if (ok) {
                                  _showFeedback(
                                    'Atendimento iniciado em ${ticket.room}!',
                                  );
                                } else {
                                  _showFeedback(
                                    ref.read(queueProvider).errorMessage ??
                                        'Erro ao iniciar atendimento.',
                                    isError: true,
                                  );
                                }
                              },
                            ),
                          FilaFacilButton(
                            label: 'Concluir Atendimento',
                            variant: FilaFacilButtonVariant.success,
                            width: 290,
                            isLoading: queueState.isActionLoading,
                            onPressed: () => _handleFinishDialog(ticket),
                          ),
                          FilaFacilButton(
                            label: 'Chamar Novamente no Painel',
                            width: 290,
                            isLoading: queueState.isActionLoading,
                            onPressed: () async {
                              final ok = await notifier.recallTicket(ticket.id);
                              if (ok) {
                                _showFeedback(
                                  'Rechamada enviada para ${ticket.patientName} (${ticket.positionBadge}) na ${ticket.room}!',
                                );
                              } else {
                                _showFeedback(
                                  ref.read(queueProvider).errorMessage ??
                                      'Erro ao rechamar no painel.',
                                  isError: true,
                                );
                              }
                            },
                          ),
                          FilaFacilButton(
                            label: 'Marcar como Não Compareceu',
                            variant: FilaFacilButtonVariant.dangerOutline,
                            width: 290,
                            height: 44,
                            isLoading: queueState.isActionLoading,
                            onPressed: () async {
                              final ok = await notifier.markAbsent(ticket.id);
                              if (!context.mounted) return;
                              if (ok) {
                                _showFeedback(
                                  'Paciente marcado como ausente.',
                                );
                                context.pop();
                              } else {
                                _showFeedback(
                                  ref.read(queueProvider).errorMessage ??
                                      'Erro ao marcar ausência.',
                                  isError: true,
                                );
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

class _FinishAttendanceDialog extends StatefulWidget {
  const _FinishAttendanceDialog({
    required this.initialCid10,
    required this.initialNotes,
  });

  final String initialCid10;
  final String initialNotes;

  @override
  State<_FinishAttendanceDialog> createState() =>
      _FinishAttendanceDialogState();
}

class _FinishAttendanceDialogState extends State<_FinishAttendanceDialog> {
  late final TextEditingController _cidController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _cidController = TextEditingController(text: widget.initialCid10);
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _cidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Finalizar Atendimento',
        style: AppTextStyles.sectionTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cidController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'CID-10 (opcional)',
              hintText: 'Ex: I10',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Anotações do atendimento',
              hintText: 'Paciente medicado e orientado...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop((
            cid10: _cidController.text.trim(),
            notes: _notesController.text.trim(),
          )),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdeSaude,
            foregroundColor: AppColors.branco,
          ),
          child: const Text('Concluir'),
        ),
      ],
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
