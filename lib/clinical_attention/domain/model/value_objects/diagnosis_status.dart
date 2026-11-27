/// Un diagnóstico pasa a SUPERSEDED cuando una reevaluación lo reemplaza; su
/// contenido nunca cambia (CON-01).
enum DiagnosisStatus {
  current('CURRENT', 'Vigente'),
  superseded('SUPERSEDED', 'Reemplazado');

  const DiagnosisStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DiagnosisStatus fromApi(String? value) =>
      DiagnosisStatus.values.where((s) => s.apiValue == value).firstOrNull ??
      DiagnosisStatus.current;
}
