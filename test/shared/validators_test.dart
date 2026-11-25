import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/shared/presentation/validators.dart';

void main() {
  test('email', () {
    expect(FormValidators.email(''), isNotNull);
    expect(FormValidators.email('roberto@'), isNotNull);
    expect(FormValidators.email(' roberto@example.com '), isNull);
  });

  test('celular peruano opcional', () {
    expect(FormValidators.optionalPeruvianMobile(''), isNull);
    expect(FormValidators.optionalPeruvianMobile('987654321'), isNull);
    expect(FormValidators.optionalPeruvianMobile('887654321'), isNotNull);
    expect(FormValidators.optionalPeruvianMobile('98765'), isNotNull);
  });

  test('teléfono al formato del backend y de vuelta', () {
    expect(FormValidators.toApiPhone('987 654 321'), '+51987654321');
    expect(FormValidators.toApiPhone(''), isNull);
    expect(FormValidators.fromApiPhone('+51987654321'), '987654321');
    expect(FormValidators.fromApiPhone(null), '');
  });
}
