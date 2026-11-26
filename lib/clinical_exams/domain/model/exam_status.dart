enum ExamStatus {
  requested('REQUESTED', 'Solicitado'),
  inProcess('IN_PROCESS', 'En proceso'),
  completed('COMPLETED', 'Completado'),
  cancelled('CANCELLED', 'Cancelado');

  const ExamStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ExamStatus fromApi(String? value) =>
      ExamStatus.values.where((s) => s.apiValue == value).firstOrNull ?? ExamStatus.requested;
}
