import 'dart:typed_data';

import 'package:petcare_mobile_application/clinical_exams/domain/model/clinical_exam.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/clinical_file.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/clinical_file_type.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_result.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_result_draft.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_status.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_type.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/open_consultation.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/repositories/clinical_exams_repository.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';
import 'package:petcare_mobile_application/shared/domain/picked_image.dart';

ClinicalExam clinicalExam({
  int id = 1,
  int petId = 1,
  ExamType type = ExamType.laboratory,
  ExamStatus status = ExamStatus.requested,
  DateTime? requestedAt,
  ExamResult? result,
  List<ClinicalFile> files = const [],
}) => ClinicalExam(
  id: id,
  consultationId: 9,
  clinicId: 5,
  petId: petId,
  requestedBy: 7,
  type: type,
  status: status,
  indication: 'Perfil bioquímico',
  requestedAt: requestedAt ?? DateTime(2026, 9, 12),
  startedAt: status == ExamStatus.requested ? null : DateTime(2026, 9, 12, 10),
  result: result,
  files: files,
);

ExamResult examResult({bool validated = false}) => ExamResult(
  id: 3,
  summary: 'Valores dentro de rango',
  values: 'ALT: 42 U/L',
  resultDate: DateTime(2026, 9, 12),
  validated: validated,
  validatedBy: validated ? 7 : null,
  validatedAt: validated ? DateTime(2026, 9, 13) : null,
);

/// In-memory Clinical Exams that applies the same state rules as the backend.
class FakeClinicalExamsRepository implements ClinicalExamsRepository {
  final Map<int, ClinicalExam> exams = {};
  final Map<int, List<OpenConsultation>> openConsultations = {};
  final List<String> calls = [];
  int _nextId = 100;

  void add(ClinicalExam exam) => exams[exam.id] = exam;

  ClinicalExam _find(int examId) =>
      exams[examId] ?? (throw const ApiError(status: 404, message: 'Exam not found'));

  ClinicalExam _save(ClinicalExam exam) => exams[exam.id] = exam;

  ClinicalExam _copy(ClinicalExam e, {ExamStatus? status, ExamResult? result, String? reason}) =>
      ClinicalExam(
        id: e.id,
        consultationId: e.consultationId,
        clinicId: e.clinicId,
        petId: e.petId,
        requestedBy: e.requestedBy,
        type: e.type,
        status: status ?? e.status,
        indication: e.indication,
        requestedAt: e.requestedAt,
        startedAt: status == ExamStatus.inProcess ? DateTime(2026, 9, 12, 10) : e.startedAt,
        completedAt: status == ExamStatus.completed ? DateTime(2026, 9, 14) : e.completedAt,
        cancellationReason: reason ?? e.cancellationReason,
        cancelledAt: reason != null ? DateTime(2026, 9, 13) : e.cancelledAt,
        result: result ?? e.result,
        files: e.files,
      );

  static const _conflict = ApiError(status: 409, message: 'Invalid exam state');

  @override
  Future<List<ClinicalExam>> getByPet(int petId) async {
    calls.add('getByPet');
    return exams.values.where((e) => e.petId == petId).toList();
  }

  @override
  Future<ClinicalExam> getById(int examId) async => _find(examId);

  @override
  Future<List<OpenConsultation>> getOpenConsultations(int petId) async =>
      openConsultations[petId] ?? const [];

  @override
  Future<ClinicalExam> request({
    required int consultationId,
    required ExamType type,
    String? indication,
  }) async {
    calls.add('request');
    final petId = openConsultations.entries
        .firstWhere(
          (entry) => entry.value.any((c) => c.id == consultationId),
          orElse: () => throw const ApiError(status: 409, message: 'Consultation not available'),
        )
        .key;
    return _save(
      ClinicalExam(
        id: _nextId++,
        consultationId: consultationId,
        clinicId: 5,
        petId: petId,
        requestedBy: 7,
        type: type,
        status: ExamStatus.requested,
        indication: indication,
        requestedAt: DateTime(2026, 9, 15),
      ),
    );
  }

  @override
  Future<ClinicalExam> start(int examId) async {
    calls.add('start');
    final exam = _find(examId);
    if (!exam.canStart) throw _conflict;
    return _save(_copy(exam, status: ExamStatus.inProcess));
  }

  @override
  Future<ClinicalExam> registerResult(int examId, ExamResultDraft draft) async {
    calls.add('registerResult');
    final exam = _find(examId);
    if (!exam.canRegisterResult) throw _conflict;
    return _save(
      _copy(
        exam,
        result: ExamResult(
          id: 3,
          summary: draft.summary,
          values: draft.values,
          interpretation: draft.interpretation,
          resultDate: draft.resultDate,
          validated: false,
        ),
      ),
    );
  }

  @override
  Future<ClinicalExam> validateResult(int examId) async {
    calls.add('validateResult');
    final exam = _find(examId);
    if (!exam.canValidateResult) throw _conflict;
    final r = exam.result!;
    return _save(
      _copy(
        exam,
        result: ExamResult(
          id: r.id,
          summary: r.summary,
          values: r.values,
          interpretation: r.interpretation,
          resultDate: r.resultDate,
          validated: true,
          validatedBy: 7,
          validatedAt: DateTime(2026, 9, 13),
        ),
      ),
    );
  }

  @override
  Future<ClinicalExam> complete(int examId) async {
    calls.add('complete');
    final exam = _find(examId);
    if (!exam.canComplete) throw _conflict;
    return _save(_copy(exam, status: ExamStatus.completed));
  }

  @override
  Future<ClinicalExam> cancel(int examId, String reason) async {
    calls.add('cancel');
    final exam = _find(examId);
    if (!exam.canCancel) throw _conflict;
    return _save(_copy(exam, status: ExamStatus.cancelled, reason: reason));
  }

  @override
  Future<ClinicalFile> uploadFile(int examId, PickedImage image) async {
    calls.add('uploadFile');
    final exam = _find(examId);
    if (!exam.canAttachFiles) throw _conflict;
    final file = ClinicalFile(
      id: _nextId++,
      fileName: image.fileName,
      type: ClinicalFileType.image,
      contentType: image.mimeType,
      sizeBytes: image.bytes.lengthInBytes,
      uploadedAt: DateTime(2026, 9, 13),
    );
    _save(exam.withFile(file));
    return file;
  }

  @override
  Future<Uint8List> downloadFile(int examId, int fileId) async {
    calls.add('downloadFile');
    return Uint8List(0);
  }
}
