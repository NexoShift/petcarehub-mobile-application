/// Formatos de fecha y edad en español, sin depender de intl.
class Formatters {
  const Formatters._();

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// 12 sep 2026
  static String date(DateTime value) {
    final local = value.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  /// "3 años", "1 año", "5 meses", "Menos de 1 mes".
  static String age(DateTime birthDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    var months = (today.year - birthDate.year) * 12 + today.month - birthDate.month;
    if (today.day < birthDate.day) months--;
    if (months < 1) return 'Menos de 1 mes';
    if (months < 12) return months == 1 ? '1 mes' : '$months meses';
    final years = months ~/ 12;
    return years == 1 ? '1 año' : '$years años';
  }
}
