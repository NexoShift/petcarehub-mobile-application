/// Grado de certeza del diagnóstico (DiagnosisType del backend).
enum DiagnosisType {
  definitive('DEFINITIVE', 'Definitivo'),
  presumptive('PRESUMPTIVE', 'Presuntivo');

  const DiagnosisType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DiagnosisType fromApi(String? value) =>
      DiagnosisType.values.where((t) => t.apiValue == value).firstOrNull ??
      DiagnosisType.presumptive;
}
