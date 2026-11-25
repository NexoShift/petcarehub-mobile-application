import 'package:material_ui/material_ui.dart';

import '../../infrastructure/image_picker_service.dart';

/// Pregunta "Tomar foto" o "Elegir de la galería". Devuelve null si cancela.
Future<ImageSourceOption?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSourceOption>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSourceOption.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, ImageSourceOption.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
