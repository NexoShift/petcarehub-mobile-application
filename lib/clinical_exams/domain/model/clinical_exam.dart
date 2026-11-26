import 'clinical_file.dart';
import 'exam_result.dart';
import 'exam_status.dart';
import 'exam_type.dart';

/// Exam requested in a consultation. The getters mirror the state rules of the backend aggregate,
/// so the app only offers the actions the API will accept.
class ClinicalExam {
  const ClinicalExam({
    required this.id,
    required this.consultationId,
    required this.clinicId,
    required this.petId,
    required this.requestedBy,
    required this.type,
    required this.status,
    required this.requestedAt,
    this.indication,
    this.startedAt,
    this.completedAt,
    this.cancellationReason,
    this.cancelledAt,
    this.result,
    this.files = const [],
  });

  static const maxIndication = 500;
  static const maxCancellationReason = 500;
  static const maxFileBytes = 10 * 1024 * 1024;

  final int id;
  final int consultationId;
  final int clinicId;
  final int petId;
  final int requestedBy;
  final ExamType type;
  final ExamStatus status;
  final String? indication;
  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final ExamResult? result;
  final List<ClinicalFile> files;

  bool get canStart => status == ExamStatus.requested;
  bool get canRegisterResult => status == ExamStatus.inProcess && result == null;
  bool get canValidateResult => status == ExamStatus.inProcess && result?.validated == false;
  bool get canComplete => status == ExamStatus.inProcess && result?.validated == true;
  bool get canCancel => status == ExamStatus.requested || status == ExamStatus.inProcess;
  bool get canAttachFiles => status == ExamStatus.inProcess || status == ExamStatus.completed;

  bool get hasValidatedResult => result?.validated == true;

  DateTime get lastActivity => cancelledAt ?? completedAt ?? startedAt ?? requestedAt;

  ClinicalExam withFile(ClinicalFile file) => ClinicalExam(
    id: id,
    consultationId: consultationId,
    clinicId: clinicId,
    petId: petId,
    requestedBy: requestedBy,
    type: type,
    status: status,
    requestedAt: requestedAt,
    indication: indication,
    startedAt: startedAt,
    completedAt: completedAt,
    cancellationReason: cancellationReason,
    cancelledAt: cancelledAt,
    result: result,
    files: [...files, file],
  );
}
