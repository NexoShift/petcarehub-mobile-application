import 'pet_sex.dart';
import 'species.dart';

/// Datos del formulario de mascota (crear o editar). La foto va aparte.
class PetDraft {
  const PetDraft({
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.sex,
  });

  final String name;
  final Species species;
  final String? breed;
  final DateTime? birthDate;
  final PetSex? sex;
}
