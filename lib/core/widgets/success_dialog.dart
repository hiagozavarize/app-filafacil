import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Componente `dialog` do Design System no Figma (`Cadastrado com sucesso!` / `Adicionado com sucesso`).
class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key, required this.message});

  final String message;

  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SuccessDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cinzaEscuro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.verdeSucesso, width: 3.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.verdeSucesso,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(
                color: AppColors.branco,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
