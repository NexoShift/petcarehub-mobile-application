import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Título de sección con acción opcional a la derecha ("Mis mascotas ..... Ver todas").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.turquoise),
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
