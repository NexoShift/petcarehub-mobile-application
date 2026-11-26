enum ClinicalFileType {
  image('IMAGE'),
  video('VIDEO'),
  document('DOCUMENT');

  const ClinicalFileType(this.apiValue);

  final String apiValue;

  static ClinicalFileType fromApi(String? value) =>
      ClinicalFileType.values.where((t) => t.apiValue == value).firstOrNull ??
      ClinicalFileType.document;
}
