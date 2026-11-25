import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/password_strength.dart';

/// Las 4 barras de seguridad de la contraseña de MM-03.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  static Color _colorFor(int score) => switch (score) {
    1 => AppColors.danger,
    2 => AppColors.warning,
    _ => AppColors.turquoise,
  };

  @override
  Widget build(BuildContext context) {
    final score = PasswordStrength.of(password);
    final color = _colorFor(score);
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i < score ? color : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 116,
          child: Text(
            score == 0 ? '' : 'Seguridad: ${PasswordStrength.label(score)}',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
