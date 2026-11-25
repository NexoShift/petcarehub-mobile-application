import '../value_objects/hydration_status.dart';
import '../value_objects/vital_signs.dart';

/// Una medición de la mascota durante la consulta. Nunca se reemplaza: cada
/// medición nueva se agrega (CON-01).
class PhysiologicalAssessment {
  const PhysiologicalAssessment({
    required this.id,
    required this.vitalSigns,
    required this.recordedAt,
    this.bodyConditionScore,
    this.hydrationStatus,
    this.mucousMembranes,
    this.capillaryRefillTimeSeconds,
    this.observations,
  });

  final int id;
  final VitalSigns vitalSigns;
  final DateTime recordedAt;

  /// De 1 (muy delgado) a 9 (obeso).
  final int? bodyConditionScore;
  final HydrationStatus? hydrationStatus;
  final String? mucousMembranes;
  final double? capillaryRefillTimeSeconds;
  final String? observations;
}
