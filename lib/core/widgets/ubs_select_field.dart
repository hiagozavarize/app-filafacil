import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// As 6 Unidades Básicas de Saúde (UBS) definidas no componente `Local` do Figma.
const List<String> kDefaultUbsUnits = <String>[
  'UBS Centro',
  'UBS Bacuri',
  'UBS Pq. do Buriti',
  'UBS Santa Inês',
  'UBS Pq. Alvorada',
  'UBS Pq. Anhanguera',
];

/// Componente `Local` (seletor dropdown de UBS) do Design System no Figma.
class UbsSelectField extends StatelessWidget {
  const UbsSelectField({
    super.key,
    required this.selectedUbs,
    required this.onChanged,
    this.label = 'Unidade de Saúde (UBS)',
    this.units = kDefaultUbsUnits,
  });

  final String selectedUbs;
  final ValueChanged<String> onChanged;
  final String label;
  final List<String> units;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.azulUbs),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.azulClaro, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: units.contains(selectedUbs) ? selectedUbs : units.first,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.azulUbs,
              ),
              style: AppTextStyles.bodyMedium,
              dropdownColor: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
              items: units
                  .map(
                    (unit) => DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit, style: AppTextStyles.bodyMedium),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
