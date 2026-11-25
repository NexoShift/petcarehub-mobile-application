import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';

/// Encabezado del dashboard: avatar, rol y saludo ("Dueño de mascota / ¡Hola, Roberto!").
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.role,
    required this.greeting,
    this.imageUrl,
    this.initials,
    this.dark = false,
  });

  final String role;
  final String greeting;
  final String? imageUrl;
  final String? initials;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        ProfileAvatar(radius: 22, imageUrl: imageUrl, initials: initials),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: text.labelSmall?.copyWith(
                  color: dark ? Colors.white70 : AppColors.textMuted,
                ),
              ),
              Text(
                greeting,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
