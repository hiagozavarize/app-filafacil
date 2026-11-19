import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Componente `Formulário` + `titulo` do Design System no Figma.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.children,
    this.padding = const EdgeInsets.all(20),
    this.spacing = 14,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (title != null) {
      items.add(
        Center(
          child: Text(
            title!,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
        ),
      );
    }

    for (var i = 0; i < children.length; i++) {
      if (items.isNotEmpty) {
        items.add(SizedBox(height: spacing));
      }
      items.add(children[i]);
    }

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cinzaClaro,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cinzaEscuro.withValues(alpha: 0.25),
          width: 0.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: items,
      ),
    );
  }
}

