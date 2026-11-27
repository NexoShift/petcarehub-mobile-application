import '../value_objects/diagnosis_status.dart';
import '../value_objects/diagnosis_type.dart';

/// Un diagnóstico no se edita: una reevaluación crea uno nuevo (CON-01).
class Diagnosis {
  const Diagnosis({
    required this.id,
    required this.description,
    required this.type,
    required this.primary,
    required this.status,
    required this.diagnosedAt,
    this.differentialDiagnoses = const [],
    this.rationale,
    this.previousDiagnosisId,
  });

  final int id;
  final String description;
  final DiagnosisType type;

  /// Diagnóstico principal. Solo puede haber uno vigente por consulta.
  final bool primary;
  final DiagnosisStatus status;
  final DateTime diagnosedAt;
  final List<String> differentialDiagnoses;
  final String? rationale;

  /// Diagnóstico que este reevalúa, si lo hay.
  final int? previousDiagnosisId;

  bool get isCurrent => status == DiagnosisStatus.current;
}
