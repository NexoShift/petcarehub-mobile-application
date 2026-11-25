import 'package:image_picker/image_picker.dart';

import '../domain/picked_image.dart';

enum ImageSourceOption { camera, gallery }

/// Puerto para elegir fotos. Las vistas lo usan sin saber que existe image_picker,
/// y en los tests se reemplaza por un fake.
abstract interface class ImagePickerService {
  /// null si el usuario cancela.
  Future<PickedImage?> pick(ImageSourceOption source);
}

/// Implementación con el paquete oficial image_picker.
class DeviceImagePickerService implements ImagePickerService {
  DeviceImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pick(ImageSourceOption source) async {
    final file = await _picker.pickImage(
      source: source == ImageSourceOption.camera ? ImageSource.camera : ImageSource.gallery,
      // Reduce la foto para no pasar los 5 MB del backend y subir más rápido.
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PickedImage(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType ?? PickedImage.mimeTypeFor(file.name),
    );
  }
}
