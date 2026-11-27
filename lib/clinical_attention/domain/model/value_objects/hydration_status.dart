/// Grado de hidratación (HydrationStatus del backend).
enum HydrationStatus {
  normal('NORMAL', 'Normal'),
  mildDehydration('MILD_DEHYDRATION', 'Deshidratación leve'),
  moderateDehydration('MODERATE_DEHYDRATION', 'Deshidratación moderada'),
  severeDehydration('SEVERE_DEHYDRATION', 'Deshidratación grave');

  const HydrationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static HydrationStatus? fromApi(String? value) =>
      HydrationStatus.values.where((s) => s.apiValue == value).firstOrNull;
}
