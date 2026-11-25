/// Datos personales que MM-03 pide en el paso 1 pero que IAM no guarda.
/// Se guardan aquí en memoria y prellenan el paso 2 ("Completa tu perfil").
class ProfileDraft {
  const ProfileDraft({required this.fullName, required this.phoneNumber});

  final String fullName;

  /// En formato del backend: "+51" seguido de 9 dígitos (máx. 12 caracteres).
  final String? phoneNumber;

  String get firstName => _parts.isEmpty ? '' : _parts.first;
  String get lastName => _parts.length < 2 ? '' : _parts.sublist(1).join(' ');

  List<String> get _parts =>
      fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
}