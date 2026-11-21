import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../queue/presentation/providers/queue_provider.dart';

/// 04. `menu inicial` (Home do Agente de Saúde - Node `9:261` / `28:2` no Figma).
/// Carrega dados em tempo real de `/api/tickets/waiting` e `/api/tickets`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String _svgAddQueue = '''
<svg width="50" height="50" viewBox="0 0 50 50" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M16.25 18.75C16.9887 18.75 17.7201 18.6045 18.4026 18.3218C19.0851 18.0391 19.7051 17.6248 20.2275 17.1025C20.7498 16.5801 21.1641 15.9601 21.4468 15.2776C21.7295 14.5951 21.875 13.8637 21.875 13.125C21.875 12.3863 21.7295 11.6549 21.4468 10.9724C21.1641 10.2899 20.7498 9.66985 20.2275 9.14752C19.7051 8.6252 19.0851 8.21086 18.4026 7.92818C17.7201 7.6455 16.9887 7.5 16.25 7.5C14.7582 7.5 13.3274 8.09263 12.2725 9.14752C11.2176 10.2024 10.625 11.6332 10.625 13.125C10.625 14.6168 11.2176 16.0476 12.2725 17.1025C13.3274 18.1574 14.7582 18.75 16.25 18.75ZM16.25 16.25C15.4212 16.25 14.6263 15.9208 14.0403 15.3347C13.4542 14.7487 13.125 13.9538 13.125 13.125C13.125 12.2962 13.4542 11.5013 14.0403 10.9153C14.6263 10.3292 15.4212 10 16.25 10C17.0788 10 17.8737 10.3292 18.4597 10.9153C19.0458 11.5013 19.375 12.2962 19.375 13.125C19.375 13.9538 19.0458 14.7487 18.4597 15.3347C17.8737 15.9208 17.0788 16.25 16.25 16.25ZM7.5 22.5C7.5 21.837 7.76339 21.2011 8.23223 20.7322C8.70107 20.2634 9.33696 20 10 20H22.5C23.163 20 23.7989 20.2634 24.2678 20.7322C24.7366 21.2011 25 21.837 25 22.5V33.75C25 34.8991 24.7737 36.0369 24.3339 37.0985C23.8942 38.1601 23.2497 39.1247 22.4372 39.9372C21.6247 40.7497 20.6601 41.3942 19.5985 41.8339C18.5369 42.2737 17.3991 42.5 16.25 42.5C15.1009 42.5 13.9631 42.2737 12.9015 41.8339C11.8399 41.3942 10.8753 40.7497 10.0628 39.9372C9.2503 39.1247 8.60578 38.1601 8.16605 37.0985C7.72633 36.0369 7.5 34.8991 7.5 33.75V22.5ZM10 22.5V33.75C10 35.4076 10.6585 36.9973 11.8306 38.1694C13.0027 39.3415 14.5924 40 16.25 40C17.9076 40 19.4973 39.3415 20.6694 38.1694C21.8415 36.9973 22.5 35.4076 22.5 33.75V22.5H10ZM24.065 15.3575C23.8458 16.128 23.512 16.8612 23.075 17.5325C24.1075 17.6525 25.0425 18.0825 25.785 18.7325C25.9367 18.7425 26.0917 18.7483 26.25 18.75C27.1363 18.7499 28.01 18.5405 28.7999 18.1386C29.5899 17.7368 30.2737 17.154 30.7956 16.4377C31.3176 15.7214 31.6629 14.892 31.8034 14.0169C31.944 13.1418 31.8757 12.2459 31.6043 11.4023C31.3329 10.5586 30.8659 9.79096 30.2415 9.162C29.6171 8.53303 28.8529 8.06052 28.0112 7.78296C27.1695 7.5054 26.2741 7.43066 25.3981 7.56483C24.522 7.69899 23.69 8.03827 22.97 8.555C23.45 9.2625 23.8225 10.05 24.065 10.8925C24.5047 10.4623 25.0616 10.1715 25.6659 10.0564C26.2702 9.94134 26.895 10.0072 27.4621 10.2457C28.0291 10.4842 28.5131 10.8848 28.8535 11.3972C29.1938 11.9096 29.3754 12.5111 29.3754 13.1263C29.3754 13.7414 29.1938 14.3429 28.8535 14.8553C28.5131 15.3677 28.0291 15.7683 27.4621 16.0068C26.895 16.2453 26.2702 16.3112 25.6659 16.1961C25.0616 16.081 24.5047 15.7877 24.065 15.3575ZM23.7475 42.14C25.054 42.53 26.4336 42.6092 27.7762 42.3714C29.1188 42.1335 30.3872 41.5853 31.4803 40.7702C32.5734 39.9552 33.4609 38.896 34.072 37.6772C34.6831 36.4583 35.0009 35.1135 35 33.75V22.5C35 21.837 34.7366 21.2011 34.2678 20.7322C33.7989 20.2634 33.163 20 32.5 20H26.8325C27.2575 20.735 27.5025 21.59 27.5025 22.5H32.5025V33.75C32.5027 34.6236 32.3197 35.4875 31.9655 36.286C31.6112 37.0845 31.0934 37.7999 30.4456 38.386C29.7978 38.9721 29.0343 39.4159 28.2045 39.6887C27.3746 39.9615 26.4967 40.0574 25.6275 39.97C25.0925 40.7733 24.4675 41.4958 23.7525 42.1375M34.07 15.3575C33.8508 16.128 33.517 16.8612 33.08 17.5325C34.1125 17.6525 35.0475 18.0825 35.79 18.7325C35.9417 18.7425 36.0967 18.7483 36.255 18.75C37.1413 18.7499 38.015 18.5405 38.8049 18.1386C39.5949 17.7368 40.2787 17.154 40.8006 16.4377C41.3226 15.7214 41.6679 14.892 41.8084 14.0169C41.949 13.1418 41.8807 12.2459 41.6093 11.4023C41.3379 10.5586 40.8709 9.79096 40.2465 9.162C39.6221 8.53303 38.8579 8.06052 38.0162 7.78296C37.1745 7.5054 36.2791 7.43066 35.4031 7.56483C34.527 7.69899 33.695 8.03827 32.975 8.555C33.455 9.2625 33.8275 10.05 34.07 10.8925C34.5097 10.4623 35.0666 10.1715 35.6709 10.0564C36.2752 9.94134 36.9 10.0072 37.4671 10.2457C38.0341 10.4842 38.5181 10.8848 38.8585 11.3972C39.1988 11.9096 39.3804 12.5111 39.3804 13.1263C39.3804 13.7414 39.1988 14.3429 38.8585 14.8553C38.5181 15.3677 38.0341 15.7683 37.4671 16.0068C36.9 16.2453 36.2752 16.3112 35.6709 16.1961C35.0666 16.081 34.5097 15.7877 34.07 15.3575ZM33.7525 42.14C34.5492 42.3783 35.3825 42.4992 36.2525 42.5025C38.5731 42.5025 40.7987 41.5806 42.4397 39.9397C44.0806 38.2987 45.0025 36.0731 45.0025 33.7525V22.5C45.0025 21.837 44.7391 21.2011 44.2703 20.7322C43.8014 20.2634 43.1655 20 42.5025 20H36.835C37.26 20.735 37.505 21.59 37.505 22.5H42.505V33.75C42.5052 34.6236 42.3222 35.4875 41.968 36.286C41.6137 37.0845 41.0959 37.7999 40.4481 38.386C39.8003 38.9721 39.0368 39.4159 38.207 39.6887C37.3771 39.9615 36.4992 40.0574 35.63 39.97C35.095 40.7733 34.47 41.4958 33.755 42.1375" fill="#F5F7FA"/>
</svg>
''';

  static const String _svgConsultQueue = '''
<svg width="50" height="50" viewBox="0 0 50 50" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M30.9382 28.1277C33.3945 28.1277 35.6632 27.3152 37.4882 25.9496L45.457 33.9184C45.75 34.2117 46.1475 34.3767 46.5621 34.377C46.7674 34.3772 46.9708 34.3369 47.1605 34.2585C47.3502 34.18 47.5226 34.065 47.6679 33.9199C47.8132 33.7748 47.9285 33.6026 48.0072 33.413C48.0859 33.2233 48.1265 33.0201 48.1266 32.8148C48.1267 32.6095 48.0865 32.4061 48.008 32.2164C47.9296 32.0267 47.8146 31.8543 47.6695 31.709L39.7007 23.7402C41.1758 21.7677 41.9418 19.355 41.8748 16.8928C41.8078 14.4306 40.9118 12.0631 39.3316 10.1737C37.7515 8.28421 35.5799 6.9834 33.1685 6.48187C30.757 5.98034 28.2468 6.30744 26.0444 7.41022C23.842 8.513 22.0763 10.3269 21.0331 12.5582C19.99 14.7895 19.7306 17.3076 20.2968 19.7047C20.8631 22.1018 22.2218 24.2376 24.1531 25.7663C26.0844 27.295 28.4752 28.127 30.9382 28.1277ZM30.9382 25.0027C28.8662 25.0027 26.8791 24.1796 25.414 22.7145C23.9488 21.2494 23.1257 19.2622 23.1257 17.1902C23.1257 15.1182 23.9488 13.1311 25.414 11.666C26.8791 10.2008 28.8662 9.37773 30.9382 9.37773C33.0102 9.37773 34.9974 10.2008 36.4625 11.666C37.9276 13.1311 38.7507 15.1182 38.7507 17.1902C38.7507 19.2622 37.9276 21.2494 36.4625 22.7145C34.9974 24.1796 33.0102 25.0027 30.9382 25.0027ZM41.2132 34.0934L38.3695 31.2527H5.93823C5.52383 31.2527 5.1264 31.4173 4.83338 31.7104C4.54035 32.0034 4.37573 32.4008 4.37573 32.8152C4.37573 33.2296 4.54035 33.6271 4.83338 33.9201C5.1264 34.2131 5.52383 34.3777 5.93823 34.3777H40.3132C40.6354 34.378 40.9497 34.2787 41.2132 34.0934ZM19.2445 25.0027C18.5936 24.0304 18.0666 22.9806 17.6757 21.8777H5.93823C5.52383 21.8777 5.1264 22.0423 4.83338 22.3354C4.54035 22.6284 4.37573 23.0258 4.37573 23.4402C4.37573 23.8546 4.54035 24.2521 4.83338 24.5451C5.1264 24.8381 5.52383 25.0027 5.93823 25.0027H19.2445ZM17.6757 12.5027C17.3216 13.4986 17.083 14.5402 16.9601 15.6277H5.93823C5.52383 15.6277 5.1264 15.4631 4.83338 15.1701C4.54035 14.8771 4.37573 14.4796 4.37573 14.0652C4.37573 13.6508 4.54035 13.2534 4.83338 12.9604C5.1264 12.6673 5.52383 12.5027 5.93823 12.5027H17.6757ZM5.93823 40.6277C5.52383 40.6277 5.1264 40.7923 4.83338 41.0854C4.54035 41.3784 4.37573 41.7758 4.37573 42.1902C4.37573 42.6046 4.54035 43.0021 4.83338 43.2951C5.1264 43.5881 5.52383 43.7527 5.93823 43.7527H40.3132C40.7276 43.7527 41.1251 43.5881 41.4181 43.2951C41.7111 43.0021 41.8757 42.6046 41.8757 42.1902C41.8757 41.7758 41.7111 41.3784 41.4181 41.0854C41.1251 40.7923 40.7276 40.6277 40.3132 40.6277H5.93823Z" fill="#F5F7FA"/>
</svg>
''';

  static const String _svgStats = '''
<svg width="50" height="50" viewBox="0 0 50 50" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M33.5415 24.2197C36.0799 24.217 38.2302 25.1029 40.0063 26.8818C41.7826 28.6609 42.6679 30.8105 42.6665 33.3447C42.6665 34.2246 42.5485 35.0787 42.312 35.9072C42.076 36.7337 41.7219 37.4992 41.2505 38.205L41.1362 38.3759L45.4478 42.6875C45.7782 43.0179 45.9478 43.439 45.9478 43.9697C45.9477 44.5003 45.7782 44.9205 45.4478 45.2509C45.1173 45.5813 44.6972 45.7509 44.1665 45.7509C43.6358 45.7509 43.2157 45.5813 42.8853 45.2509L38.5737 40.9394L38.4028 41.0527C37.6954 41.5243 36.9294 41.8782 36.104 42.1142C35.2769 42.3507 34.423 42.4697 33.5415 42.4697C31.003 42.4697 28.8528 41.5842 27.0767 39.8095C25.3006 38.0348 24.4152 35.8846 24.4165 33.3447C24.4179 30.8046 25.304 28.6552 27.0786 26.8818C28.8534 25.1084 31.0028 24.2225 33.5415 24.2197ZM33.5415 27.8857C32.0187 27.8857 30.7216 28.4146 29.6665 29.4697C28.6115 30.5247 28.0835 31.8219 28.0835 33.3447C28.0836 34.8672 28.6117 36.1638 29.6665 37.2187C30.7216 38.2738 32.0187 38.8027 33.5415 38.8027C35.0644 38.8027 36.3614 38.2738 37.4165 37.2187C38.4713 36.1638 38.9994 34.8673 38.9995 33.3447C38.9995 31.8219 38.4715 30.5247 37.4165 29.4697C36.3614 28.4146 35.0644 27.8857 33.5415 27.8857ZM43.9302 4.29391C44.4674 4.18729 44.9399 4.29962 45.3667 4.63474L45.3726 4.63962L45.3784 4.64352C45.7742 4.91753 46.0059 5.28363 46.0825 5.75485C46.16 6.23232 46.077 6.68357 45.8296 7.11716L39.9966 16.3886L39.9956 16.3896C39.2425 17.601 38.1686 18.1982 36.7456 18.1982C35.4083 18.1982 34.3631 17.6857 33.5884 16.6494L33.437 16.4345L30.7808 12.4756L30.564 12.1533L30.3599 12.4843L25.4116 20.5049L25.4106 20.5078C24.723 21.6537 23.7277 22.2681 22.4038 22.3662C21.1612 22.4581 20.1373 22.0651 19.312 21.1797L19.1499 20.9961L19.1479 20.9941L16.5435 17.9726L16.3208 17.7148L16.1411 18.0049L9.7876 28.2646L9.67627 28.4316C9.40794 28.7942 9.04303 29.021 8.56982 29.1162C8.03323 29.224 7.56108 29.1109 7.13428 28.7734L7.12744 28.7685L7.12158 28.7636L6.98096 28.6572C6.67039 28.3973 6.48535 28.0661 6.41943 27.6552C6.34311 27.1788 6.42505 26.726 6.67041 26.289L13.0239 16.08C13.7458 14.9323 14.7593 14.3272 16.0835 14.2461C17.4117 14.1648 18.4892 14.6267 19.3394 15.6406L19.3413 15.6425L21.894 18.6113L22.1167 18.8711L22.2964 18.58L27.2437 10.5586L27.2446 10.5576C27.9996 9.31028 29.0761 8.68949 30.4985 8.6738C31.9227 8.65811 33.0143 9.24748 33.8003 10.4599L33.8022 10.4629L36.4585 14.4209L36.6733 14.7402L36.8784 14.415L42.7114 5.1445L42.7144 5.13962C42.9897 4.68077 43.3894 4.40133 43.9302 4.29391Z" fill="#F5F7FA"/>
</svg>
''';

  static const String _svgHistory = '''
<svg width="50" height="50" viewBox="0 0 50 50" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M10.1391 33.461C11.9013 37.0249 14.7601 39.9296 18.2953 41.7485C21.8047 43.5514 25.8066 44.16 29.6933 43.4818C33.5918 42.7957 37.1635 40.8662 39.8745 37.9818C42.6098 35.0694 44.3516 31.3649 44.8495 27.4006C45.3542 23.4271 44.5932 19.3957 42.6745 15.8797C40.7734 12.3906 37.8017 9.60438 34.1974 7.93183C30.6176 6.27384 26.5946 5.82912 22.7391 6.66517C18.8849 7.50058 15.7266 9.40058 13.1141 12.4048C12.7995 12.7381 11.5828 14.0839 10.5724 16.1152M16.8766 16.6693L9.35784 18.1693L7.50159 10.4193M26.2516 18.7527V27.086L32.5016 31.2527" stroke="#F5F7FA" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(queueProvider.notifier).loadQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(authProvider).agent;
    final queueState = ref.watch(queueProvider);
    final nextTicket = queueState.nextInLineTicket;

    return Scaffold(
      appBar: FilaFacilHeader(
        agentName: agent.name,
        agentRole: agent.roleDisplayLabel,
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(queueProvider.notifier).loadQueue(),
        color: AppColors.azulUbs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // Banner da Unidade Ativa
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cinzaClaro,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.azulClaro),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Unidade Ativa: ${agent.assignedUbs}',
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: AppColors.azulUbs,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (queueState.isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.azulUbs,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${queueState.waitingCount} pacientes aguardando • ${queueState.inAttendanceCount.toString().padLeft(2, '0')} em atendimento agora',
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (queueState.errorMessage != null) ...[
                    const SizedBox(height: 12),
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
                            Icons.cloud_off_rounded,
                            color: AppColors.vermelho,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              queueState.errorMessage!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.vermelho,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.read(queueProvider.notifier).loadQueue(),
                            child: const Text('Tentar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Grid 2x2 de Opções do Agente de Saúde (150x150 cada no Figma)
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      _AgentMenuCard(
                        label: 'Adicionar na Fila',
                        svgAsset: _svgAddQueue,
                        onTap: () => context.push('/add-to-queue'),
                      ),
                      _AgentMenuCard(
                        label: 'Consultar Fila',
                        svgAsset: _svgConsultQueue,
                        onTap: () => context.push('/consult-queue'),
                      ),
                      _AgentMenuCard(
                        label: 'Estatísticas',
                        svgAsset: _svgStats,
                        onTap: () => context.push('/stats'),
                      ),
                      _AgentMenuCard(
                        label: 'Histórico',
                        svgAsset: _svgHistory,
                        onTap: () => context.push('/history'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Card Atalho Próximo da Fila
                  if (nextTicket != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ref
                            .read(queueProvider.notifier)
                            .selectTicketForCall(nextTicket);
                        context.push('/patient-call');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cinzaClaro,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.azulClaro),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Próximo da Fila (${nextTicket.positionBadge})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.azulUbs,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.verdeClaro,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      nextTicket.room,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.verdeSaude,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${nextTicket.patientName} • ${nextTicket.specialty} (${nextTicket.scheduledTime})',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (queueState.hasLoadedOnce && !queueState.isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cinzaClaro,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.azulClaro),
                      ),
                      child: Text(
                        'Nenhum paciente na fila no momento. Toque em "Adicionar na Fila" para emitir uma nova senha.',
                        style: AppTextStyles.bodyRegular.copyWith(fontSize: 13),
                      ),
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

class _AgentMenuCard extends StatelessWidget {
  const _AgentMenuCard({
    required this.label,
    required this.svgAsset,
    required this.onTap,
  });

  final String label;
  final String svgAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.azulUbs,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 150,
          height: 150,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.string(svgAsset, width: 50, height: 50),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cinzaClaro,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
