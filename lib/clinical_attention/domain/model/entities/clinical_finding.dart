import '../value_objects/body_system.dart';
import '../value_objects/finding_severity.dart';

/// Lo que el veterinario observó en un sistema del cuerpo.
class ClinicalFinding {
  const ClinicalFinding({
    required this.id,
    required this.bodySystem,
    required this.description,
    required this.recordedAt,
    this.severity,
  });

  final int id;
  final BodySystem bodySystem;
  final String description;
  final DateTime recordedAt;
  final FindingSeverity? severity;
}
