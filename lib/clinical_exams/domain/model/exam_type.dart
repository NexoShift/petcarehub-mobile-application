enum ExamType {
  radiography('RADIOGRAPHY', 'Radiografía'),
  ultrasound('ULTRASOUND', 'Ecografía'),
  laboratory('LABORATORY', 'Laboratorio'),
  other('OTHER', 'Otro');

  const ExamType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ExamType fromApi(String? value) =>
      ExamType.values.where((t) => t.apiValue == value).firstOrNull ?? ExamType.other;
}
