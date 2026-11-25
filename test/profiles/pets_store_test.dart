import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/profiles/application/clinic_patients_store.dart';
import 'package:petcare_mobile_application/profiles/application/pets_store.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_draft.dart';
import 'package:petcare_mobile_application/profiles/domain/model/species.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';

import '../support/fakes.dart';

void main() {
  late FakePetsRepository repository;

  setUp(() {
    repository = FakePetsRepository()
      ..add(pet(id: 1, name: 'Max'))
      ..add(pet(id: 2, name: 'Luna', species: Species.cat, code: 'PET-LUNA2345'))
      ..add(pet(id: 3, name: 'Rocky', ownerId: 9, code: 'PET-ROCKY234'));
  });

  group('PetsStore', () {
    test('carga solo las mascotas del dueño y elige la primera', () async {
      final store = PetsStore(repository: repository);
      await store.load(1);
      expect(store.status, LoadStatus.loaded);
      expect(store.pets.map((p) => p.name), ['Max', 'Luna']);
      expect(store.selectedPet!.name, 'Max');

      store.select(2);
      expect(store.selectedPet!.name, 'Luna');
    });

    test('un error queda en el estado', () async {
      repository.nextError = const ApiError(status: 0, message: 'sin red');
      final store = PetsStore(repository: repository);
      await store.load(1);
      expect(store.status, LoadStatus.error);
      expect(store.error, 'sin red');
    });

    test('crear agrega, selecciona y sube la foto', () async {
      final store = PetsStore(repository: repository);
      await store.load(1);
      final created = await store.create(
        ownerId: 1,
        draft: const PetDraft(name: 'Toby', species: Species.dog),
        image: fakeImage(),
      );
      expect(store.pets.last.name, 'Toby');
      expect(store.selectedPet!.id, created.id);
      expect(repository.created.single.withImage, isTrue);
    });

    test('editar reemplaza en la lista', () async {
      final store = PetsStore(repository: repository);
      await store.load(1);
      await store.update(petId: 1, draft: const PetDraft(name: 'Maximus', species: Species.dog));
      expect(store.byId(1)!.name, 'Maximus');
    });

    test('detalle trae la mascota y sus clínicas', () async {
      repository.clinicsByPet[1] = [vetSur];
      final store = PetsStore(repository: repository);
      final detail = await store.fetchDetail(1);
      expect(detail.pet.name, 'Max');
      expect(detail.clinics.single.name, 'Clínica VetSur');
    });

    test('clear deja todo vacío', () async {
      final store = PetsStore(repository: repository);
      await store.load(1);
      store.clear();
      expect(store.pets, isEmpty);
      expect(store.status, LoadStatus.idle);
    });
  });

  group('ClinicPatientsStore', () {
    setUp(() => repository.patientsByClinic[5] = [2, 1]);

    test('ordena por nombre y filtra por especie y texto', () async {
      final store = ClinicPatientsStore(repository: repository);
      await store.load(5);
      expect(store.patients.map((p) => p.name), ['Luna', 'Max']);
      expect(store.countOf(Species.cat), 1);

      store.filterBySpecies(Species.dog);
      expect(store.patients.map((p) => p.name), ['Max']);

      store.filterBySpecies(null);
      store.search('luna2');
      expect(store.patients.map((p) => p.name), ['Luna']);

      store.search('golden');
      expect(store.patients.map((p) => p.name), ['Max']);
    });

    test('buscar por código y registrar como paciente', () async {
      final store = ClinicPatientsStore(repository: repository);
      await store.load(5);
      final rocky = await store.findByCode('PET-ROCKY234');
      expect(rocky!.name, 'Rocky');
      expect(store.isPatient(rocky.id), isFalse);

      await store.register(clinicId: 5, pet: rocky);

      expect(store.isPatient(rocky.id), isTrue);
      expect(store.allPatients, hasLength(3));
    });

    test('registrar dos veces lanza 409', () async {
      final store = ClinicPatientsStore(repository: repository);
      await store.load(5);
      await expectLater(
        store.register(clinicId: 5, pet: repository.pets[1]!),
        throwsA(isA<ApiError>().having((e) => e.isConflict, 'conflict', isTrue)),
      );
    });
  });
}
