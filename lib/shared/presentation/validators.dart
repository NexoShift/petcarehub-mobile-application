/// Validadores de formularios reutilizables. Devuelven el mensaje de error o null.
class FormValidators {
  const FormValidators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _peruvianMobile = RegExp(r'^9\d{8}$');

  static String? required(String? value, [String message = 'Este campo es obligatorio']) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo electrónico';
    return _email.hasMatch(value.trim()) ? null : 'Ingresa un correo válido';
  }

  /// Celular peruano opcional: 9 dígitos que empiezan con 9 (sin el +51).
  static String? optionalPeruvianMobile(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return null;
    return _peruvianMobile.hasMatch(digits) ? null : 'Ingresa 9 dígitos que empiecen con 9';
  }

  /// Convierte lo que escribe el usuario ("987 654 321") al formato del backend ("+51987654321").
  static String? toApiPhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\s'), '');
    return digits.isEmpty ? null : '+51$digits';
  }

  /// Lo inverso de [toApiPhone], para prellenar el campo.
  static String fromApiPhone(String? value) => (value ?? '').replaceFirst('+51', '');
}
