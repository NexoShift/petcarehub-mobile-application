import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';

/// "ID: PET-98102" con botón para copiar (el dueño lo comparte con la clínica).
class PetCodeChip extends StatelessWidget {
  const PetCodeChip({super.key, required this.petCode, this.copyable = true});

  final String petCode;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: !copyable
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: petCode));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Código $petCode copiado')),
                );
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'ID: $petCode',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
                fontFamily: 'monospace',
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 4),
              const Icon(Icons.copy, size: 12, color: AppColors.turquoise),
            ],
          ],
        ),
      ),
    );
  }
}
