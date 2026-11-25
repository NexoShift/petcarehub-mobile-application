enum PersonSex {
  male('MALE', 'Masculino'),
  female('FEMALE', 'Femenino');

  const PersonSex(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PersonSex? fromApi(String? value) =>
      PersonSex.values.where((sex) => sex.apiValue == value).firstOrNull;
}
