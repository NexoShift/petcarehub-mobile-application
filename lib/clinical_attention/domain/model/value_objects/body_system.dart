/// Sistema del cuerpo al que pertenece un hallazgo (BodySystem del backend).
enum BodySystem {
  integumentary('INTEGUMENTARY', 'Piel y pelaje'),
  ocular('OCULAR', 'Ojos'),
  otic('OTIC', 'Oídos'),
  digestive('DIGESTIVE', 'Digestivo'),
  respiratory('RESPIRATORY', 'Respiratorio'),
  cardiovascular('CARDIOVASCULAR', 'Cardiovascular'),
  musculoskeletal('MUSCULOSKELETAL', 'Musculoesquelético'),
  nervous('NERVOUS', 'Nervioso'),
  urinary('URINARY', 'Urinario'),
  reproductive('REPRODUCTIVE', 'Reproductivo'),
  other('OTHER', 'Otro');

  const BodySystem(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static BodySystem fromApi(String? value) =>
      BodySystem.values.where((s) => s.apiValue == value).firstOrNull ?? BodySystem.other;
}
