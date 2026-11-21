import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Componente `placeholder` para telas de fundo Azul UBS (Login e Cadastro).
class AuthPlaceholderField extends StatelessWidget {
  const AuthPlaceholderField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.authFieldLabel),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cinzaClaro,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: AppTextStyles.bodyRegular,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.cinzaEscuro.withValues(alpha: 0.5),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Componente `modelo de pergunta do form` para formulários internos (Adicionar na Fila e Perfil).
class FormQuestionField extends StatelessWidget {
  const FormQuestionField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.inputFormatters,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.formLabel),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.cinzaEscuro.withValues(alpha: 0.35),
              width: 0.6,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            inputFormatters: inputFormatters,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.cinzaEscuro.withValues(alpha: 0.45),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
