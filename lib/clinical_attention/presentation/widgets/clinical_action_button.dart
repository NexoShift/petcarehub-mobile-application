import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';

/// Acción secundaria dentro de una fase ("+ Registrar medición").
class ClinicalActionButton extends StatelessWidget {
  const ClinicalActionButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.turquoise),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
    );
  }
}
