import 'pet_sex.dart';
import 'species.dart';

/// Mascota (PetResource). `petCode` es el código que el dueño comparte con la
/// clínica para que lo registre como paciente.
class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.petCode,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.sex,
    this.profileImageUrl,
  });

  final int id;
  final int ownerId;
  final String petCode;
  final String name;
  final Species species;
  final String? breed;
  final DateTime? birthDate;
  final PetSex? sex;
  final String? profileImageUrl;

  /// "Canino • Golden Retriever"
  String get speciesAndBreed =>
      breed == null || breed!.isEmpty ? species.label : '${species.label} • $breed';
}
