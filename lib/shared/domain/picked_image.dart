import 'dart:typed_data';

/// Imagen elegida por el usuario (cámara o galería), lista para subir.
///
/// Se guarda en bytes para que funcione igual en Android, iOS y web.
class PickedImage {
  const PickedImage({required this.bytes, required this.fileName, required this.mimeType});

  final Uint8List bytes;
  final String fileName;

  /// image/jpeg, image/png o image/webp: los únicos que acepta el backend.
  final String mimeType;

  static const allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  /// Límite del backend (ProfileImageStorageService): 5 MB.
  static const maxBytes = 5 * 1024 * 1024;

  bool get isAllowedType => allowedMimeTypes.contains(mimeType);
  bool get isTooLarge => bytes.lengthInBytes > maxBytes;

  /// Deduce el tipo por la extensión del archivo.
  static String mimeTypeFor(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
