/// Lo que falta registrar para poder finalizar una consulta. [apiValue] es el
/// código que el backend devuelve en `details` del 409 al completar.
enum PendingItem {
  anamnesis('anamnesis', 'Registrar la anamnesis'),
  physiologicalAssessment(
    'physiologicalAssessment',
    'Registrar al menos una evaluación fisiológica',
  ),
  primaryDiagnosis('primaryDiagnosis', 'Registrar un diagnóstico principal');

  const PendingItem(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PendingItem? fromApi(String? value) =>
      PendingItem.values.where((i) => i.apiValue == value).firstOrNull;
}
