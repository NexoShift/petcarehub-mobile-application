/// Estado de la consulta (ConsultationStatus del backend):
/// CREATED → IN_PROGRESS → COMPLETED, o CANCELLED antes de finalizar.
enum ConsultationStatus {
  created('CREATED', 'Programada'),
  inProgress('IN_PROGRESS', 'En curso'),
  completed('COMPLETED', 'Finalizada'),
  cancelled('CANCELLED', 'Cancelada');

  const ConsultationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ConsultationStatus fromApi(String? value) =>
      ConsultationStatus.values.where((s) => s.apiValue == value).firstOrNull ??
      ConsultationStatus.created;
}
