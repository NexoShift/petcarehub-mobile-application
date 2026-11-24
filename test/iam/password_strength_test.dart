import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/iam/domain/model/password_strength.dart';

void main() {
  test('cuenta las 4 reglas como la web', () {
    expect(PasswordStrength.of(''), 0);
    expect(PasswordStrength.of('abcdefgh'), 1);
    expect(PasswordStrength.of('Abcdefgh'), 2);
    expect(PasswordStrength.of('Abcdefg1'), 3);
    expect(PasswordStrength.of('S3cur3P@ssw0rd!'), 4);
    expect(PasswordStrength.label(4), 'Fuerte');
  });
}
