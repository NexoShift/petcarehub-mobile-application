import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/entities/anamnesis.dart';
import '../../domain/model/entities/clinical_finding.dart';
import '../../domain/model/entities/diagnosis.dart';
import '../../domain/model/entities/physiological_assessment.dart';
import '../../domain/model/value_objects/body_system.dart';
import '../../domain/model/value_objects/consultation_status.dart';
import '../../domain/model/value_objects/diagnosis_status.dart';
import '../../domain/model/value_objects/diagnosis_type.dart';
import '../../domain/model/value_objects/finding_severity.dart';
import '../../domain/model/value_objects/hydration_status.dart';
import '../../domain/model/value_objects/vital_signs.dart';

/// Convierte ClinicalConsultationResource (JSON) en el agregado de dominio.
/// El dominio no sabe nada de JSON: todo el mapeo vive aquí.
abstract final class ClinicalConsultationAssembler {
  static List<ClinicalConsultation> fromJsonList(dynamic json) => _list(json, fromJson);

  static ClinicalConsultation fromJson(Map<String, dynamic> json) => ClinicalConsultation(
    id: _int(json['id'])!,
    petId: _int(json['petId'])!,
    veterinarianId: _int(json['veterinarianId']) ?? 0,
    clinicId: _int(json['clinicId']) ?? 0,
    consultingRoomId: _int(json['consultingRoomId']),
    reason: json['reason'] as String? ?? '',
    status: ConsultationStatus.fromApi(json['status'] as String?),
    createdAt: _requiredDate(json['createdAt']),
    startedAt: _date(json['startedAt']),
    completedAt: _date(json['completedAt']),
    cancellationReason: json['cancellationReason'] as String?,
    cancelledAt: _date(json['cancelledAt']),
    anamnesis: json['anamnesis'] == null
        ? null
        : anamnesis(json['anamnesis'] as Map<String, dynamic>),
    physiologicalAssessments: _list(json['physiologicalAssessments'], physiologicalAssessment),
    findings: _list(json['findings'], clinicalFinding),
    diagnoses: _list(json['diagnoses'], diagnosis),
  );

  static Anamnesis anamnesis(Map<String, dynamic> json) => Anamnesis(
    id: _int(json['id']) ?? 0,
    chiefComplaint: json['chiefComplaint'] as String? ?? '',
    evolutionTime: json['evolutionTime'] as String? ?? '',
    symptoms: _strings(json['symptoms']),
    diet: json['diet'] as String?,
    behavior: json['behavior'] as String?,
    previousTreatments: json['previousTreatments'] as String?,
    ownerObservations: json['ownerObservations'] as String?,
  );

  static PhysiologicalAssessment physiologicalAssessment(Map<String, dynamic> json) =>
      PhysiologicalAssessment(
        id: _int(json['id']) ?? 0,
        vitalSigns: VitalSigns(
          weightKg: _double(json['weightKg']) ?? 0,
          temperatureCelsius: _double(json['temperatureCelsius']) ?? 0,
          heartRateBpm: _int(json['heartRateBpm']) ?? 0,
          respiratoryRateBpm: _int(json['respiratoryRateBpm']) ?? 0,
        ),
        bodyConditionScore: _int(json['bodyConditionScore']),
        hydrationStatus: HydrationStatus.fromApi(json['hydrationStatus'] as String?),
        mucousMembranes: json['mucousMembranes'] as String?,
        capillaryRefillTimeSeconds: _double(json['capillaryRefillTimeSeconds']),
        observations: json['observations'] as String?,
        recordedAt: _requiredDate(json['recordedAt']),
      );

  static ClinicalFinding clinicalFinding(Map<String, dynamic> json) => ClinicalFinding(
    id: _int(json['id']) ?? 0,
    bodySystem: BodySystem.fromApi(json['bodySystem'] as String?),
    description: json['description'] as String? ?? '',
    severity: FindingSeverity.fromApi(json['severity'] as String?),
    recordedAt: _requiredDate(json['recordedAt']),
  );

  static Diagnosis diagnosis(Map<String, dynamic> json) => Diagnosis(
    id: _int(json['id']) ?? 0,
    description: json['description'] as String? ?? '',
    type: DiagnosisType.fromApi(json['type'] as String?),
    primary: json['primary'] as bool? ?? false,
    status: DiagnosisStatus.fromApi(json['status'] as String?),
    diagnosedAt: _requiredDate(json['diagnosedAt']),
    differentialDiagnoses: _strings(json['differentialDiagnoses']),
    rationale: json['rationale'] as String?,
    previousDiagnosisId: _int(json['previousDiagnosisId']),
  );

  static int? _int(dynamic value) => (value as num?)?.toInt();

  static double? _double(dynamic value) => (value as num?)?.toDouble();

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value as String);

  static DateTime _requiredDate(dynamic value) =>
      _date(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

  static List<String> _strings(dynamic value) => [for (final v in value as List? ?? const []) '$v'];

  static List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) map) => [
    for (final item in value as List? ?? const []) map(item as Map<String, dynamic>),
  ];
}
