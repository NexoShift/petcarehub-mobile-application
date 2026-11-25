import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_draft.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_sex.dart';
import 'package:petcare_mobile_application/profiles/domain/model/species.dart';
import 'package:petcare_mobile_application/profiles/infrastructure/pets_api.dart';
import 'package:petcare_mobile_application/shared/infrastructure/api_client.dart';

import '../support/fakes.dart';

void main() {
  PetsApi apiWith(MockClientHandler handler) => PetsApi(ApiClient(
        baseUrl: 'http://api.test/api/v1',
        tokenProvider: InMemorySessionStorage(),
        httpClient: MockClient(handler),
      ));

  const petJson = {'id': 4, 'ownerId': 1, 'petCode': 'PET-ABCDEFGH', 'name': 'Max', 'species': 'DOG'};

  test('crear mascota envía multipart con LocalDate y la foto con su Content-Type', () async {
    late String body;
    late String contentType;
    final api = apiWith((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/pets');
      contentType = request.headers['content-type']!;
      body = utf8.decode(request.bodyBytes, allowMalformed: true);
      return http.Response(jsonEncode(petJson), 201);
    });

    await api.createPet(
      ownerId: 1,
      draft: PetDraft(
        name: 'Max',
        species: Species.dog,
        birthDate: DateTime(2023, 1, 5),
        sex: PetSex.male,
      ),
      image: fakeImage(mimeType: 'image/png'),
    );

    expect(contentType, startsWith('multipart/form-data'));
    expect(body, contains('name="ownerId"\r\n\r\n1'));
    expect(body, contains('name="species"\r\n\r\nDOG'));
    expect(body, contains('name="birthDate"\r\n\r\n2023-01-05'));
    expect(body, contains('name="sex"\r\n\r\nMALE'));
    expect(body, isNot(contains('name="breed"')));
    expect(body, contains('name="image"; filename="foto.jpg"'));
    expect(body, contains('content-type: image/png'));
  });

  test('editar mascota usa PUT JSON', () async {
    final api = apiWith((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/v1/pets/4');
      expect(jsonDecode(request.body), {
        'name': 'Max',
        'species': 'CAT',
        'breed': 'Siamés',
        'birthDate': null,
        'sex': null,
      });
      return http.Response(jsonEncode(petJson), 200);
    });
    await api.updatePet(
      petId: 4,
      draft: const PetDraft(name: 'Max', species: Species.cat, breed: 'Siamés'),
    );
  });

  test('buscar por código: 404 o 400 devuelven null', () async {
    for (final status in [404, 400]) {
      final api = apiWith((request) async {
        expect(request.url.queryParameters['petCode'], 'PET-ABCDEFGH');
        return http.Response('{"status":$status,"message":"x"}', status);
      });
      expect(await api.findPetByCode(' pet-abcdefgh '), isNull);
    }
  });

  test('registrar paciente envía el petId', () async {
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/clinics/5/patients');
      expect(jsonDecode(request.body), {'petId': 4});
      return http.Response('{}', 201);
    });
    await api.registerClinicPatient(clinicId: 5, petId: 4);
  });
}
