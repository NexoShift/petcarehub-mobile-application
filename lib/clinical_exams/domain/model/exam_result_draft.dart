/// Result typed by the veterinarian, checked with the same limits as RegisterExamResultResource.
class ExamResultDraft {
  ExamResultDraft({
    required String summary,
    required this.resultDate,
    String? values,
    String? interpretation,
    DateTime? today,
  }) : summary = summary.trim(),
       values = _blankToNull(values),
       interpretation = _blankToNull(interpretation) {
    if (this.summary.isEmpty) throw ArgumentError('summary');
    if (this.summary.length > maxSummary) throw ArgumentError('summary');
    if ((this.values?.length ?? 0) > maxValues) throw ArgumentError('values');
    if ((this.interpretation?.length ?? 0) > maxInterpretation) {
      throw ArgumentError('interpretation');
    }
    final now = today ?? DateTime.now();
    if (DateTime(
      resultDate.year,
      resultDate.month,
      resultDate.day,
    ).isAfter(DateTime(now.year, now.month, now.day))) {
      throw ArgumentError('resultDate');
    }
  }

  static const maxSummary = 2000;
  static const maxValues = 4000;
  static const maxInterpretation = 2000;

  final String summary;
  final String? values;
  final String? interpretation;
  final DateTime resultDate;

  static String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
