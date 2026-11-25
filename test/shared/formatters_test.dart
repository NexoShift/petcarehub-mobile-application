import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/shared/domain/picked_image.dart';
import 'package:petcare_mobile_application/shared/presentation/formatters.dart';

import '../support/fakes.dart';

void main() {
  final today = DateTime(2026, 11, 25);

  test('edad en años y meses', () {
    expect(Formatters.age(DateTime(2023, 1, 15), now: today), '3 años');
    expect(Formatters.age(DateTime(2025, 11, 25), now: today), '1 año');
    expect(Formatters.age(DateTime(2026, 6, 26), now: today), '4 meses');
    expect(Formatters.age(DateTime(2026, 10, 25), now: today), '1 mes');
    expect(Formatters.age(DateTime(2026, 11, 20), now: today), 'Menos de 1 mes');
  });

  test('fecha corta en español', () {
    expect(Formatters.date(DateTime(2026, 9, 12)), '12 sep 2026');
  });

  test('fecha y hora', () {
    expect(Formatters.dateTime(DateTime(2026, 9, 12, 8, 5)), '12 sep 2026, 08:05');
  });

  test('PickedImage valida tipo y tamaño como el backend', () {
    expect(fakeImage().isAllowedType, isTrue);
    expect(fakeImage(mimeType: 'image/gif').isAllowedType, isFalse);
    expect(fakeImage(size: PickedImage.maxBytes + 1).isTooLarge, isTrue);
    expect(PickedImage.mimeTypeFor('FOTO.PNG'), 'image/png');
    expect(PickedImage.mimeTypeFor('foto.heic'), 'image/jpeg');
  });
}
