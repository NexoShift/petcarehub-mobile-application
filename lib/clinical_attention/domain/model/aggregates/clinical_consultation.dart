import '../entities/anamnesis.dart';
import '../entities/clinical_finding.dart';
import '../entities/diagnosis.dart';
import '../entities/physiological_assessment.dart';
import '../value_objects/consultation_status.dart';
import '../value_objects/pending_item.dart';

/// Agregado raíz de Clinical Attention: el registro clínico de una visita.
///
/// Es espejo de ClinicalConsultation del backend, que es quien decide los
/// cambios de estado. Aquí viven las reglas que la app necesita para saber qué
/// se puede hacer. Mascota, veterinario, clínica y consultorio son de Profiles:
/// solo se guarda su id.
class ClinicalConsultation {
  const ClinicalConsultation({
    required this.id,
    required this.petId,
    required this.veterinarianId,
    required this.clinicId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.consultingRoomId,
    this.startedAt,
    this.completedAt,
    this.cancellationReason,
    this.cancelledAt,
    this.anamnesis,
    this.physiologicalAssessments = const [],
    this.findings = const [],
    this.diagnoses = const [],
  });

  final int id;
  final int petId;
  final int veterinarianId;
  final int clinicId;
  final int? consultingRoomId;
  final String reason;
  final ConsultationStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final Anamnesis? anamnesis;
  final List<PhysiologicalAssessment> physiologicalAssessments;
  final List<ClinicalFinding> findings;
  final List<Diagnosis> diagnoses;

  /// Fecha que se muestra: la de cierre si terminó, si no la de creación.
  DateTime get date => completedAt ?? cancelledAt ?? createdAt;

  bool get canStart => status == ConsultationStatus.created;

  /// Solo se registran datos clínicos con la consulta en curso.
  bool get isInProgress => status == ConsultationStatus.inProgress;

  bool get canCancel => canStart || isInProgress;

  /// Finalizada o cancelada: registro cerrado, de solo lectura.
  bool get isClosed => !canCancel;

  bool get canRegisterAnamnesis => isInProgress && anamnesis == null;

  PhysiologicalAssessment? get latestAssessment => physiologicalAssessments.lastOrNull;

  List<Diagnosis> get currentDiagnoses => diagnoses.where((d) => d.isCurrent).toList();

  List<Diagnosis> get supersededDiagnoses => diagnoses.where((d) => !d.isCurrent).toList();

  Diagnosis? get primaryDiagnosis => currentDiagnoses.where((d) => d.primary).firstOrNull;

  /// Solo puede haber un diagnóstico principal vigente.
  bool get canRegisterPrimaryDiagnosis => isInProgress && primaryDiagnosis == null;

  /// Diagnóstico para los resúmenes: el principal o, si falta, el primero vigente.
  String? get mainDiagnosis => (primaryDiagnosis ?? currentDiagnoses.firstOrNull)?.description;

  List<PendingItem> get pendingItems => [
    if (anamnesis == null) PendingItem.anamnesis,
    if (physiologicalAssessments.isEmpty) PendingItem.physiologicalAssessment,
    if (primaryDiagnosis == null) PendingItem.primaryDiagnosis,
  ];

  bool get canComplete => isInProgress && pendingItems.isEmpty;
}
