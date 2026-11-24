/// Fuerza de la contraseña de 0 a 4 (las 4 barras de MM-03). Mismas reglas que la web.
class PasswordStrength {
  const PasswordStrength._();

  static const minLength = 8;
  static const maxLength = 72;

  static int of(String password) {
    if (password.isEmpty) return 0;
    return [
      password.length >= minLength,
      RegExp('[a-z]').hasMatch(password) && RegExp('[A-Z]').hasMatch(password),
      RegExp(r'\d').hasMatch(password),
      RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ].where((ok) => ok).length;
  }

  static String label(int score) => switch (score) {
    0 => '',
    1 => 'Débil',
    2 => 'Regular',
    3 => 'Buena',
    _ => 'Fuerte',
  };
}
