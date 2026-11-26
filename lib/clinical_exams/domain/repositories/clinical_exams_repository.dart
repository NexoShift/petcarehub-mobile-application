import 'dart:typed_data';

import '../../../shared/domain/picked_image.dart';
import '../model/clinical_exam.dart';
import '../model/clinical_file.dart';
import '../model/exam_result_draft.dart';
import '../model/exam_type.dart';
import '../model/open_consultation.dart';

abstract interface class ClinicalExamsRepository {
  Future<List<ClinicalExam>> getByPet(int petId);

  Future<ClinicalExam> getById(int examId);

  Future<List<OpenConsultation>> getOpenConsultations(int petId);

  Future<ClinicalExam> request({
    required int consultationId,
    required ExamType type,
    String? indication,
  });

  Future<ClinicalExam> start(int examId);

  Future<ClinicalExam> registerResult(int examId, ExamResultDraft draft);

  Future<ClinicalExam> validateResult(int examId);

  Future<ClinicalExam> complete(int examId);

  Future<ClinicalExam> cancel(int examId, String reason);

  Future<ClinicalFile> uploadFile(int examId, PickedImage image);

  Future<Uint8List> downloadFile(int examId, int fileId);
}
