import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';

/// Tarjeta blanca con ícono, título, ayuda y contenido, como en MM-07 y MM-18.
class ClinicalCard extends StatelessWidget {
  const ClinicalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.turquoiseSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.deepBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Par "etiqueta: valor" de los registros de solo lectura. No se dibuja sin valor.
class ClinicalFact extends StatelessWidget {
  const ClinicalFact({super.key, required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value!, style: text.bodyMedium),
        ],
      ),
    );
  }
}

/// Nota informativa con fondo turquesa suave.
class ClinicalNote extends StatelessWidget {
  const ClinicalNote(this.message, {super.key, this.icon = Icons.verified_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.turquoiseSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.deepBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}
