import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/status_chip.dart';

/// Acción rápida del dashboard (MM-04). Si [onTap] es null se muestra como
/// "Pronto": la función llega en una parte siguiente de la app.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: AppCard(
        onTap: onTap,
        color: highlighted ? AppColors.turquoiseSoft : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: highlighted ? Colors.white : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.deepBlue, size: 20),
                ),
                const Spacer(),
                if (!enabled) const StatusChip(label: 'Pronto', color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            Text(subtitle, style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
