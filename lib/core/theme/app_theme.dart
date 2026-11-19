import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tema Material 3 configurado com os tokens do FilaFácil UBS.
final class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.azulUbs,
      primary: AppColors.azulUbs,
      secondary: AppColors.verdeSaude,
      surface: AppColors.branco,
      error: AppColors.vermelho,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.branco,
      fontFamily: AppTextStyles.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azulUbs,
        foregroundColor: AppColors.branco,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.azulProfundo,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.branco,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

