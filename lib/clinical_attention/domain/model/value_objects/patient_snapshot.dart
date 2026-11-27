/// Datos de la mascota que Clinical Attention necesita mostrar.
///
/// La mascota es de Profiles; aquí solo se guarda una copia de lectura que
/// entrega ExternalProfilesService (ACL).
class PatientSnapshot {
  const PatientSnapshot({
    required this.petId,
    required this.ownerId,
    required this.code,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.photoUrl,
  });

  final int petId;
  final int ownerId;
  final String code;
  final String name;
  final String species;
  final String? breed;
  final DateTime? birthDate;
  final String? photoUrl;

  /// "Canino • Golden Retriever"
  String get speciesAndBreed => breed == null || breed!.isEmpty ? species : '$species • $breed';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || [name, code, breed ?? ''].any((value) => value.toLowerCase().contains(q));
  }
}
