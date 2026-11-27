/// Severidad de un hallazgo clínico (FindingSeverity del backend).
enum FindingSeverity {
  mild('MILD', 'Leve'),
  moderate('MODERATE', 'Moderada'),
  severe('SEVERE', 'Grave');

  const FindingSeverity(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FindingSeverity? fromApi(String? value) =>
      FindingSeverity.values.where((s) => s.apiValue == value).firstOrNull;
}
