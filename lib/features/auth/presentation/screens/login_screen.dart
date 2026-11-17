import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/filafacil_button.dart';
import '../../../../core/widgets/filafacil_logo.dart';
import '../../../../core/widgets/filafacil_text_field.dart';
import '../providers/auth_provider.dart';

/// 02. `Login` (Node `9:204` / `31:102` no Figma).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _cpfController = TextEditingController(text: '042.891.653-20');
  final _passwordController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await ref
        .read(authProvider.notifier)
        .login(
          cpf: _cpfController.text,
          password: _passwordController.text,
        );
    if (success && mounted) {
      context.go('/home');
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
                const SizedBox(height: 56),
                AuthPlaceholderField(
                  label: 'CPF:',
                  hintText: '000.000.000-00',
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                AuthPlaceholderField(
                  label: 'Senha:',
                  hintText: '••••••••••••',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 36),
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
