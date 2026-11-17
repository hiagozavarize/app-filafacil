import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'filafacil_logo.dart';

/// Componente `barra de menu` (412x53) do Design System no Figma.
class FilaFacilHeader extends StatelessWidget implements PreferredSizeWidget {
  const FilaFacilHeader({
    super.key,
    required this.agentName,
    this.agentRole = 'Agente de Saúde',
    this.showBackButton = true,
    this.onBack,
    this.onProfileTap,
  });

  final String agentName;
  final String agentRole;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  static const String _backSvg = '''
<svg width="32" height="18" viewBox="0 0 32 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M25 10H7C6.44 10 6 9.56 6 9C6 8.44 6.44 8 7 8H25C25.56 8 26 8.44 26 9C26 9.56 25.56 10 25 10Z" fill="#F5F7FA"/>
<path d="M12 17C11.8688 17.0016 11.7388 16.9757 11.6183 16.9241C11.4977 16.8724 11.3893 16.7961 11.3 16.7L4.3 9.7C3.9 9.3 3.9 8.68 4.3 8.28L11.3 1.3C11.7 0.9 12.32 0.9 12.72 1.3C13.12 1.7 13.12 2.32 12.72 2.72L6.42 9.02L12.72 15.32C13.12 15.72 13.12 16.34 12.72 16.74C12.52 16.94 12.26 17.04 12.02 17.04L12 17Z" fill="#F5F7FA"/>
</svg>
''';

  static const String _perfilSvg = '''
<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="40" height="40" rx="10" fill="white"/>
<path d="M17.175 18.825C16.3917 18.0417 16 17.1 16 16C16 14.9 16.3917 13.9583 17.175 13.175C17.9583 12.3917 18.9 12 20 12C21.1 12 22.0417 12.3917 22.825 13.175C23.6083 13.9583 24 14.9 24 16C24 17.1 23.6083 18.0417 22.825 18.825C22.0417 19.6083 21.1 20 20 20C18.9 20 17.9583 19.6083 17.175 18.825ZM12 28V25.2C12 24.6333 12.146 24.1127 12.438 23.638C12.73 23.1633 13.1173 22.8007 13.6 22.55C14.6333 22.0333 15.6833 21.646 16.75 21.388C17.8167 21.13 18.9 21.0007 20 21C21.1 20.9993 22.1833 21.1287 23.25 21.388C24.3167 21.6473 25.3667 22.0347 26.4 22.55C26.8833 22.8 27.271 23.1627 27.563 23.638C27.855 24.1133 28.0007 24.634 28 25.2V28H12Z" fill="#7DB9E8"/>
</svg>
''';

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.azulUbs,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap:
                      onBack ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: SvgPicture.string(_backSvg, width: 32, height: 18),
                  ),
                )
              else
                const FilaFacilLogo(fontSize: 20, badgeFontSize: 10),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onProfileTap ?? () => context.push('/profile'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          agentName,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.branco,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          agentRole,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: AppColors.branco,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    SvgPicture.string(_perfilSvg, width: 40, height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
