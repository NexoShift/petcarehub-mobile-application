import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/profiles/domain/model/person_sex.dart';
import 'package:petcare_mobile_application/profiles/domain/model/pet_sex.dart';
import 'package:petcare_mobile_application/profiles/domain/model/species.dart';
import 'package:petcare_mobile_application/profiles/infrastructure/assemblers/profile_assemblers.dart';

void main() {
  test('PetResource completo', () {
    final pet = ProfileAssemblers.pet({
      'id': 4,
      'ownerId': 1,
      'petCode': 'PET-98102ABC',
      'name': 'Max',
      'species': 'DOG',
      'breed': 'Golden Retriever',
      'birthDate': '2023-01-15',
      'sex': 'MALE',
      'profileImageUrl': 'https://s3/max.jpg',
    });
    expect(pet.species, Species.dog);
    expect(pet.sex, PetSex.male);
    expect(pet.birthDate, DateTime(2023, 1, 15));
    expect(pet.speciesAndBreed, 'Canino • Golden Retriever');
  });

  test('PetSearchResource (sin ownerId ni fecha) y especie desconocida', () {
    final pet = ProfileAssemblers.pet({
      'id': 9,
      'petCode': 'PET-XYZ23456',
      'name': 'Nemo',
      'species': 'FISH',
      'breed': null,
    });
    expect(pet.ownerId, 0);
    expect(pet.species, Species.other);
    expect(pet.birthDate, isNull);
    expect(pet.speciesAndBreed, 'Otro');
  });

  test('PetOwner y Veterinarian', () {
    final owner = ProfileAssemblers.petOwner({
      'id': 1,
      'userId': 2,
      'firstName': 'Roberto',
      'lastName': 'García',
      'email': 'r@x.pe',
      'sex': 'MALE',
    });
    expect(owner.fullName, 'Roberto García');
    expect(owner.sex, PersonSex.male);

    final vet = ProfileAssemblers.veterinarian({
      'id': 7,
      'userId': 3,
      'clinicId': 5,
      'firstName': 'Francisco',
      'lastName': 'Mendoza',
      'email': 'v@x.pe',
      'licenseNumber': '9841',
    });
    expect(vet.clinicId, 5);
    expect(vet.fullName, 'Francisco Mendoza');
  });

  test('list convierte un arreglo JSON', () {
    final clinics = ProfileAssemblers.list([
      {'id': 1, 'accountId': 2, 'name': 'VetSur'},
    ], ProfileAssemblers.clinic);
    expect(clinics.single.name, 'VetSur');
  });
}
