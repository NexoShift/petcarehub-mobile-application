/// Especie de la mascota (enum Species del backend).
enum Species {
  dog('DOG', 'Canino'),
  cat('CAT', 'Felino'),
  other('OTHER', 'Otro');

  const Species(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static Species fromApi(String? value) =>
      Species.values.where((s) => s.apiValue == value).firstOrNull ?? Species.other;
}
