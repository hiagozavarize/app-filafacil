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
import '../providers/auth_provider.dart';

/// 05. `menu inicial - perfil` (Node `6:492` no Figma).
/// Integrada a `GET /api/users/profile` e `PUT /api/users/profile`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _cpfController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _registrationController;
  late String _selectedUbs;

  @override
  void initState() {
    super.initState();
    final agent = ref.read(authProvider).agent;
    _nameController = TextEditingController(text: agent.name);
    _cpfController = TextEditingController(text: agent.cpf);
    _emailController = TextEditingController(text: agent.email);
    _phoneController = TextEditingController(text: agent.phone);
    _registrationController = TextEditingController(text: agent.registration);
    _selectedUbs = agent.assignedUbs;

    Future<void>.microtask(_loadProfileFromApi);
  }

  Future<void> _loadProfileFromApi() async {
    await ref.read(authProvider.notifier).refreshProfile();
    if (!mounted) return;
    final agent = ref.read(authProvider).agent;
    setState(() {
      _nameController.text = agent.name;
      _cpfController.text = agent.cpf;
      _emailController.text = agent.email;
      _phoneController.text = agent.phone;
      _registrationController.text = agent.registration;
      _selectedUbs = agent.assignedUbs;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final current = ref.read(authProvider).agent;
    final updated = current.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      registration: _registrationController.text.trim(),
      assignedUbs: _selectedUbs,
    );
    final ok = await ref.read(authProvider.notifier).updateProfile(updated);
    if (!mounted) return;
    if (ok) {
      await SuccessDialog.show(
        context,
        message: 'Perfil atualizado com sucesso!',
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Não foi possível salvar o perfil.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final agent = authState.agent;

    return Scaffold(
      appBar: FilaFacilHeader(
        agentName: agent.name,
        agentRole: agent.roleDisplayLabel,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meu Perfil', style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                SectionCard(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.azulUbs,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        agent.initials,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.branco,
                        ),
                      ),
                    ),
                    Text(
                      agent.name,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verdeClaro,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        agent.cns.isNotEmpty
                            ? '${agent.roleDisplayLabel} • CNS ${agent.cns}'
                            : '${agent.roleDisplayLabel} • Ativo',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.verdeSaude,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SectionCard(
                  title: 'Dados Cadastrais',
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormQuestionField(
                      label: 'Nome Completo',
                      hintText: 'Nome completo do profissional',
                      controller: _nameController,
                    ),
                    FormQuestionField(
                      label: 'CPF',
                      hintText: '000.000.000-00',
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                    FormQuestionField(
                      label: 'E-mail Institucional',
                      hintText: 'agente@saude.ubs.gov.br',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                    ),
                    FormQuestionField(
                      label: 'Telefone / WhatsApp',
                      hintText: '(00) 00000-0000',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    FormQuestionField(
                      label: 'Registro Profissional (CRM / COREN / Matrícula)',
                      hintText: 'Ex: CRM-MA 12345',
                      controller: _registrationController,
                    ),
                    UbsSelectField(
                      selectedUbs: _selectedUbs,
                      onChanged: (ubs) => setState(() => _selectedUbs = ubs),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: FilaFacilButton(
                        label: 'Salvar Alterações',
                        width: 220,
                        isLoading: authState.isLoading,
                        onPressed: _saveProfile,
                      ),
                    ),
                    Center(
                      child: FilaFacilButton(
                        label: 'Encerrar Sessão',
                        variant: FilaFacilButtonVariant.dangerOutline,
                        width: 220,
                        height: 44,
                        onPressed: _logout,
                      ),
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
