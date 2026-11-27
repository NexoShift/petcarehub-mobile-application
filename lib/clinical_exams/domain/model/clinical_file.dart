import 'clinical_file_type.dart';

class ClinicalFile {
  const ClinicalFile({
    required this.id,
    required this.fileName,
    required this.type,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  final int id;
  final String fileName;
  final ClinicalFileType type;
  final String contentType;
  final int sizeBytes;
  final DateTime uploadedAt;

  bool get isImage => type == ClinicalFileType.image;
}
