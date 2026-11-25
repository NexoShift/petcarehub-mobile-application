import 'consultation_status.dart';

/// Resumen de una consulta para el dashboard. Solo lo que el móvil muestra por ahora;
/// el detalle completo (anamnesis, hallazgos...) llega con MM-07.
class ConsultationSummary {
  const ConsultationSummary({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.mainDiagnosis,
  });

  final int id;
  final int petId;
  final int clinicId;
  final String reason;
  final ConsultationStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Descripción del diagnóstico principal, si el vet ya lo registró.
  final String? mainDiagnosis;

  /// Fecha que se muestra: la de cierre si terminó, si no la de creación.
  DateTime get date => completedAt ?? createdAt;
}
