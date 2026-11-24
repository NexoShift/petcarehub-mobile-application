import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Etiqueta arriba a la izquierda, ayuda opcional a la derecha y el campo debajo,
/// como en MM-02 y MM-03 ("Contraseña ........ Mínimo 8 caracteres").
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, this.hint, required this.child});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.labelMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: small?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (hint != null)
              Text(hint!, style: small?.copyWith(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
