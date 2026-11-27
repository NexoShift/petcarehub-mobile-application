/// Números de las constantes fisiológicas, con punto o coma decimal.
abstract final class ClinicalFormatters {
  /// 28.5 → "28.5", 30.0 → "30".
  static String decimal(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  static double? parseDecimal(String? text) =>
      double.tryParse((text ?? '').trim().replaceAll(',', '.'));

  static int? parseInteger(String? text) => int.tryParse((text ?? '').trim());

  /// "Consulta N.° 12"
  static String consultationTitle(int id) => 'Consulta N.° $id';
}
