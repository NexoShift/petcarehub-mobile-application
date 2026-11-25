/// Entrevista clínica con el tutor. Se registra una sola vez por consulta.
class Anamnesis {
  const Anamnesis({
    required this.id,
    required this.chiefComplaint,
    required this.evolutionTime,
    this.symptoms = const [],
    this.diet,
    this.behavior,
    this.previousTreatments,
    this.ownerObservations,
  });

  final int id;
  final String chiefComplaint;
  final String evolutionTime;
  final List<String> symptoms;
  final String? diet;
  final String? behavior;
  final String? previousTreatments;
  final String? ownerObservations;
}
