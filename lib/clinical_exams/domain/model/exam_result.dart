class ExamResult {
  const ExamResult({
    required this.id,
    required this.summary,
    required this.resultDate,
    required this.validated,
    this.values,
    this.interpretation,
    this.validatedBy,
    this.validatedAt,
  });

  final int id;
  final String summary;
  final String? values;
  final String? interpretation;
  final DateTime resultDate;
  final bool validated;
  final int? validatedBy;
  final DateTime? validatedAt;
}
