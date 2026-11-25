import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/infrastructure/acl/profiles_acl_service.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';
import 'package:petcare_mobile_application/shared/infrastructure/api_client.dart';

import '../../support/fakes.dart';

void main() {
  late FakePetsRepository pets;
  late FakeProfilesRepository profiles;

  setUp(() {
    pets = FakePetsRepository();
    profiles = FakeProfilesRepository()..clinicsByAccountId[20] = vetSur;
  });

  ProfilesAclService acl([Map<String, Object> responses = const {}]) => ProfilesAclService(
    pets: pets,
    profiles: profiles,
    client: ApiClient(
      baseUrl: 'http://api.test/api/v1',
      tokenProvider: InMemorySessionStorage(),
      httpClient: MockClient((request) async {
        final body = responses[request.url.path.replaceFirst('/api/v1', '')];
        return body == null
            ? http.Response('{"message":"Forbidden"}', 403)
            : http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
      }),
    ),
  );

  test('traduce la mascota de Profiles y ordena los pacientes por nombre', () async {
    pets
      ..add(pet(id: 1, name: 'Max'))
      ..add(pet(id: 2, name: 'bobby'))
      ..patientsByClinic[5] = [1, 2];
    final patients = await acl().getClinicPatients(5);
    expect(patients.map((p) => p.name), ['bobby', 'Max']);
    expect(patients.last.speciesAndBreed, 'Canino • Golden Retriever');
  });

  test('una mascota que no existe es un error del dominio clínico', () async {
    await expectLater(
      acl().getPatient(99),
      throwsA(
        isA<ClinicalAttentionException>().having(
          (e) => e.code,
          'code',
          ClinicalAttentionErrorCode.petNotFound,
        ),
      ),
    );
  });

  test('sin red al listar pacientes', () async {
    pets.nextError = const ApiError(status: 0, message: 'sin red');
    await expectLater(
      acl().getClinicPatients(5),
      throwsA(
        isA<ClinicalAttentionException>().having(
          (e) => e.code,
          'code',
          ClinicalAttentionErrorCode.noConnection,
        ),
      ),
    );
  });

  test('solo los consultorios activos, y vacío si no hay permiso', () async {
    final rooms = await acl({
      '/clinics/5/consulting-rooms': [
        {'id': 3, 'name': 'Consultorio 1', 'active': true},
        {'id': 4, 'name': 'Consultorio 2', 'active': false},
      ],
    }).getActiveConsultingRooms(5);
    expect(rooms.single.name, 'Consultorio 1');
    expect(await acl().getActiveConsultingRooms(5), isEmpty);
  });

  test('arma los nombres de la atención', () async {
    final staff = await acl({
      '/veterinarians/7': {
        'firstName': 'Francisco',
        'lastName': 'Mendoza',
        'licenseNumber': '9841',
      },
      '/pet-owners/1': {'firstName': 'Roberto', 'lastName': 'García'},
    }).getAttendingStaff(consultation(), ownerId: 1);
    expect(staff.veterinarianName, 'Francisco Mendoza');
    expect(staff.licenseNumber, '9841');
    expect(staff.clinicName, 'Clínica VetSur');
    expect(staff.ownerName, 'Roberto García');
  });

  test('lo que Profiles no entrega queda en null, sin fallar', () async {
    final staff = await acl().getAttendingStaff(consultation(), ownerId: 1);
    expect(staff.veterinarianName, isNull);
    expect(staff.ownerName, isNull);
    expect(staff.clinicName, 'Clínica VetSur');
  });
}
