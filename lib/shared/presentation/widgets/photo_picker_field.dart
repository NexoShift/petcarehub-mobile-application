import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/picked_image.dart';
import '../../infrastructure/image_picker_service.dart';
import '../theme/app_colors.dart';
import 'image_source_sheet.dart';
import 'profile_avatar.dart';

/// Foto circular con botón de cámara. Abre "Tomar foto / Galería", valida
/// tipo y tamaño (5 MB) y devuelve la imagen por [onPicked].
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.onPicked,
    this.imageUrl,
    this.preview,
    this.initials,
    this.fallbackIcon = Icons.pets,
    this.radius = 48,
  });

  final ValueChanged<PickedImage> onPicked;
  final String? imageUrl;
  final PickedImage? preview;
  final String? initials;
  final IconData fallbackIcon;
  final double radius;

  Future<void> _pick(BuildContext context) async {
    final picker = context.read<ImagePickerService>();
    final messenger = ScaffoldMessenger.of(context);
    final source = await showImageSourceSheet(context);
    if (source == null) return;
    final image = await picker.pick(source);
    if (image == null) return;
    if (!image.isAllowedType) {
      messenger.showSnackBar(const SnackBar(content: Text('Usa una foto JPG, PNG o WEBP.')));
      return;
    }
    if (image.isTooLarge) {
      messenger.showSnackBar(const SnackBar(content: Text('La foto pesa más de 5 MB.')));
      return;
    }
    onPicked(image);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          ProfileAvatar(
            radius: radius,
            imageUrl: imageUrl,
            preview: preview?.bytes,
            initials: initials,
            fallbackIcon: fallbackIcon,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.turquoise,
              shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
              child: IconButton(
                tooltip: 'Cambiar foto',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.photo_camera, size: 18, color: AppColors.navy),
                onPressed: () => _pick(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
