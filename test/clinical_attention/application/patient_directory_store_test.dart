import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_attention/application/patient_directory_store.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/clinical_attention_exception.dart';
import 'package:petcare_mobile_application/clinical_attention/domain/model/value_objects/attending_staff.dart';

import '../../support/fakes.dart';

void main() {
  late FakeExternalProfilesService profiles;
  late PatientDirectoryStore store;

  setUp(() {
    profiles = FakeExternalProfilesService();
    store = PatientDirectoryStore(profiles: profiles);
  });

  test('carga pacientes y consultorios, y busca por nombre, raza o código', () async {
    await store.loadClinic(5);
    expect(store.patients, hasLength(2));
    expect(store.consultingRooms.single.name, 'Consultorio 1');
    expect(store.search('golden').single.name, 'Max');
    expect(store.search('LUNALUNA').single.name, 'Luna');
    expect(store.search('zzz'), isEmpty);
    expect(store.patientOf(1)!.name, 'Max');
  });

  test('error al cargar y reintento', () async {
    profiles.nextError = const ClinicalAttentionException(ClinicalAttentionErrorCode.noConnection);
    await store.loadClinic(5);
    expect(store.error, ClinicalAttentionErrorCode.noConnection);
    expect(store.patients, isNull);

    await store.loadClinic(5);
    expect(store.error, isNull);
    expect(store.patients, hasLength(2));
  });

  test('una mascota que no existe no rompe la consulta', () async {
    expect(await store.loadPatient(99), isNull);
  });

  test('los nombres se piden una vez, salvo que Profiles no haya respondido', () async {
    profiles.staff = const AttendingStaff();
    await store.loadStaff(consultation());
    profiles.staff = const AttendingStaff(veterinarianName: 'Francisco Mendoza');
    await store.loadStaff(consultation());
    await store.loadStaff(consultation());
    expect(profiles.staffCalls, 2);
    expect(store.staffOf(1)!.veterinarianName, 'Francisco Mendoza');
  });

  test('al cerrar sesión no queda nada', () async {
    await store.loadClinic(5);
    store.clear();
    expect(store.patients, isNull);
    expect(store.consultingRooms, isEmpty);
    expect(store.patientOf(1), isNull);
  });
}
