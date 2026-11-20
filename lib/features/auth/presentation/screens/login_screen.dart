import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_logo.dart';
import '../../../../core/widgets/filafacil_text_field.dart';
import '../providers/auth_provider.dart';

/// 02. `Login` (Node `9:204` / `31:102` no Figma).
/// Integrada a `POST /api/auth/login` e `POST /api/auth/forgot-password`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController(
      text: EnvConfig.useMockBackend ? '042.891.653-20' : '',
    );
    _passwordController = TextEditingController(
      text: EnvConfig.useMockBackend ? '123456' : '',
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authProvider.notifier)
        .login(
          login: _loginController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.vermelho,
          ),
        );
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final recoveryController = TextEditingController(
      text: _loginController.text.trim(),
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Recuperar Senha',
            style: AppTextStyles.sectionTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe seu CPF ou e-mail institucional cadastrado na UBS:',
                style: AppTextStyles.bodyRegular,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recoveryController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'CPF ou e-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulUbs,
                foregroundColor: AppColors.branco,
              ),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    final emailOrCpf = recoveryController.text.trim();
    recoveryController.dispose();

    if (submitted != true || emailOrCpf.isEmpty || !mounted) return;

    final ok = await ref
        .read(authProvider.notifier)
        .forgotPassword(emailOrCpf: emailOrCpf);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Instruções de recuperação enviadas, caso o cadastro exista.',
          ),
          backgroundColor: AppColors.verdeSaude,
        ),
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Não foi possível solicitar a recuperação.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.azulUbs,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FilaFacilLogo(fontSize: 36, badgeFontSize: 14),
                const SizedBox(height: 52),
                AuthPlaceholderField(
                  label: 'CPF ou E-mail:',
                  hintText: '000.000.000-00 ou email@ubs.gov.br',
                  controller: _loginController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                AuthPlaceholderField(
                  label: 'Senha:',
                  hintText: '••••••••••••',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : _showForgotPasswordDialog,
                  child: Text(
                    'Esqueci minha senha',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.cinzaClaro,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.cinzaClaro,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Ainda não possui registro?',
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.branco,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/register'),
                      child: Text(
                        'Clique aqui',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.branco,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.branco,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilaFacilButton(
                  label: 'Fazer Login',
                  variant: FilaFacilButtonVariant.lightBlue,
                  width: 180,
                  height: 44,
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
