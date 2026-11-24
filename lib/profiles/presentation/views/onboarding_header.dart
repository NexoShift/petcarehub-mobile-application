import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';

/// Encabezado "Paso 2 de 2" del onboarding.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.turquoiseSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Paso 2 de 2: Perfil',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.deepBlue),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
