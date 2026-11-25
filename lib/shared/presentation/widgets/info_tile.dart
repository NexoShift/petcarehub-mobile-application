import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Celda "Especie / Canino" de la ficha de la mascota (MM-05).
class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
              ),
              Icon(icon, size: 16, color: AppColors.turquoise),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}
