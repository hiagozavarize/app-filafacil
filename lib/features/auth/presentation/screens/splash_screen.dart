import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// 01. `Tela inicial` (Splash Screen única do app - Node `25:83` no Figma).
/// Verifica sessão JWT ativa na API antes de redirecionar para `/home` ou `/login`.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      Future<void>.delayed(const Duration(milliseconds: 1400)),
      ref.read(authProvider.notifier).restoreSession(),
    ]);
    final isAuthenticated = results[1] as bool;
    _navigateTo(isAuthenticated ? '/home' : '/login');
  }

  void _navigateTo(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulUbs,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _navigateTo('/login'),
          child: Center(
            child: Image.asset(
              'assets/images/logo_filafacil_vertical.png',
              key: const Key('splash_logo_image'),
              width: 242,
              height: 165,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
