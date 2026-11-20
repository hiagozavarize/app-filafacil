import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_logo.dart';
import '../../../../core/widgets/filafacil_text_field.dart';
import '../../../../core/widgets/success_dialog.dart';
import '../providers/auth_provider.dart';

/// 03. `Cadastro` + modal `dialog` (`Cadastrado com sucesso!`) (Nodes `9:228` e `9:223` no Figma).
/// Integrada a `POST /api/auth/register`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _termsAccepted = true;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.vermelho,
      ),
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty ||
        _cpfController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Preencha nome, CPF, e-mail e senha para realizar o cadastro.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('As senhas digitadas não conferem.');
      return;
    }

    if (!_termsAccepted) {
      _showError('É obrigatório aceitar os termos de uso do SUS.');
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .register(
          name: _nameController.text,
          cpf: _cpfController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          role: 'RECEPCAO',
          unitName: 'UBS Centro',
          termsAccepted: _termsAccepted,
        );

    if (!mounted) return;
    if (!success) {
      final error = ref.read(authProvider).errorMessage;
      _showError(error ?? 'Não foi possível concluir o cadastro.');
      return;
    }

    await SuccessDialog.show(
      context,
      message: 'Cadastrado com sucesso!',
    );

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.azulUbs,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.cinzaClaro,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const FilaFacilLogo(fontSize: 34, badgeFontSize: 14),
              const SizedBox(height: 28),
              AuthPlaceholderField(
                label: 'Nome completo:',
                hintText: 'Ex: Hiago Zavarize',
                controller: _nameController,
              ),
              const SizedBox(height: 12),
              AuthPlaceholderField(
                label: 'CPF:',
                hintText: '000.000.000-00',
                controller: _cpfController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AuthPlaceholderField(
                label: 'Email:',
                hintText: 'agente@saude.ubs.gov.br',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AuthPlaceholderField(
                label: 'Telefone (opcional):',
                hintText: '(98) 98877-6655',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AuthPlaceholderField(
                label: 'Senha:',
                hintText: '••••••••••••',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              AuthPlaceholderField(
                label: 'Confirmar senha:',
                hintText: '••••••••••••',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 248,
                child: Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (v) =>
                          setState(() => _termsAccepted = v ?? false),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.verdeSaude
                            : AppColors.cinzaClaro,
                      ),
                      checkColor: AppColors.branco,
                      side: const BorderSide(color: AppColors.cinzaClaro),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _termsAccepted = !_termsAccepted),
                        child: Text(
                          'Aceito os termos de uso e sigilo do SUS',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.branco,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilaFacilButton(
                label: 'Fazer cadastro',
                variant: FilaFacilButtonVariant.lightBlue,
                width: 180,
                height: 44,
                isLoading: authState.isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
