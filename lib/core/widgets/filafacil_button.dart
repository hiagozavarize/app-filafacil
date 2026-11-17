import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum FilaFacilButtonVariant { primary, lightBlue, success, dangerOutline }

/// Componente `botão` do Design System no Figma.
class FilaFacilButton extends StatelessWidget {
  const FilaFacilButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FilaFacilButtonVariant.primary,
    this.width = 220,
    this.height = 46,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FilaFacilButtonVariant variant;
  final double? width;
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderSide) = switch (variant) {
      FilaFacilButtonVariant.primary => (
        AppColors.azulUbs,
        AppColors.branco,
        BorderSide.none,
      ),
      FilaFacilButtonVariant.lightBlue => (
        AppColors.azulClaro,
        AppColors.branco,
        BorderSide.none,
      ),
      FilaFacilButtonVariant.success => (
        AppColors.verdeSucesso,
        AppColors.branco,
        BorderSide.none,
      ),
      FilaFacilButtonVariant.dangerOutline => (
        AppColors.branco,
        AppColors.vermelho,
        const BorderSide(color: AppColors.vermelho, width: 1.5),
      ),
    };

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderSide,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: fgColor,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.buttonText.copyWith(color: fgColor),
              ),
      ),
    );
  }
}
