import '../clinical_attention_exception.dart';

/// Validaciones compartidas por los commands. Un dato inválido lanza
/// [ClinicalAttentionErrorCode.invalidRequest] antes de llamar a la API.
abstract final class CommandValidation {
  static Never _fail() =>
      throw const ClinicalAttentionException(ClinicalAttentionErrorCode.invalidRequest);

  static int requireId(int value) => value > 0 ? value : _fail();

  static int? optionalId(int? value) => value == null ? null : requireId(value);

  static String requireText(String value, int maxLength) {
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed.length > maxLength ? _fail() : trimmed;
  }

  static String? optionalText(String? value, int maxLength) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length > maxLength) _fail();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Recorta cada elemento, quita vacíos y repetidos, y valida cantidad y tamaño.
  static List<String> cleanList(
    Iterable<String> values, {
    required int maxItems,
    required int maxItemLength,
  }) {
    final clean = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      final repeated = clean.any((item) => item.toLowerCase() == trimmed.toLowerCase());
      if (trimmed.isEmpty || repeated) continue;
      if (trimmed.length > maxItemLength) _fail();
      clean.add(trimmed);
    }
    if (clean.length > maxItems) _fail();
    return List.unmodifiable(clean);
  }
}
