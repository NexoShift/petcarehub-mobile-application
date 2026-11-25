import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Foto circular con respaldo: si no hay URL (o falla la carga) muestra
/// las iniciales o un ícono. [preview] tiene prioridad: es la foto recién elegida.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.preview,
    this.initials,
    this.fallbackIcon = Icons.person,
    this.radius = 24,
  });

  final String? imageUrl;
  final Uint8List? preview;
  final String? initials;
  final IconData fallbackIcon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.turquoiseSoft,
      alignment: Alignment.center,
      child: initials != null && initials!.isNotEmpty
          ? Text(
              initials!,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.7,
              ),
            )
          : Icon(fallbackIcon, color: AppColors.turquoise, size: radius),
    );

    Widget image;
    if (preview != null) {
      image = Image.memory(preview!, width: size, height: size, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      image = fallback;
    }

    return ClipOval(child: SizedBox.square(dimension: size, child: image));
  }

  /// "Roberto García" → "RG"
  static String initialsOf(String firstName, String lastName) {
    String first(String value) => value.trim().isEmpty ? '' : value.trim()[0].toUpperCase();
    return '${first(firstName)}${first(lastName)}';
  }
}
