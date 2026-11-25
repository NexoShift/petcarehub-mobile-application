/// Sexo biológico de la mascota (enum PetSex del backend).
enum PetSex {
  male('MALE', 'Macho'),
  female('FEMALE', 'Hembra');

  const PetSex(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PetSex? fromApi(String? value) =>
      PetSex.values.where((s) => s.apiValue == value).firstOrNull;
}
