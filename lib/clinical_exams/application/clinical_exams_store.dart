import 'package:flutter/foundation.dart';

import '../../shared/domain/api_error.dart';
import '../../shared/domain/picked_image.dart';
import '../domain/model/clinical_exam.dart';
import '../domain/model/exam_result_draft.dart';
import '../domain/model/exam_type.dart';
import '../domain/model/open_consultation.dart';
import '../domain/repositories/clinical_exams_repository.dart';

/// Exams per pet, newest first. Every command returns the updated exam and refreshes the cache,
/// so the pet section and the detail screen stay in sync.
class ClinicalExamsStore extends ChangeNotifier {
  ClinicalExamsStore({required this._repository});

  final ClinicalExamsRepository _repository;

  final Map<int, List<ClinicalExam>> _byPet = {};
  final Map<int, ClinicalExam> _byId = {};
  final Set<int> _loading = {};
  final Map<int, String> _errors = {};
  final Map<int, Uint8List> _fileBytes = {};

  List<ClinicalExam>? examsOf(int petId) => _byPet[petId];
  bool isLoading(int petId) => _loading.contains(petId);
  String? errorOf(int petId) => _errors[petId];

  ClinicalExam? cached(int examId) => _byId[examId];

  Future<void> loadForPet(int petId, {bool force = false}) async {
    if (_loading.contains(petId) || (!force && _byPet.containsKey(petId))) return;
    _loading.add(petId);
    _errors.remove(petId);
    notifyListeners();
    try {
      final exams = await _repository.getByPet(petId);
      _byPet[petId] = _sorted(exams);
      _byId.addAll({for (final exam in exams) exam.id: exam});
    } on ApiError catch (error) {
      _errors[petId] = error.message;
    } finally {
      _loading.remove(petId);
      notifyListeners();
    }
  }

  Future<ClinicalExam> fetch(int examId) async => _store(await _repository.getById(examId));

  Future<List<OpenConsultation>> openConsultationsOf(int petId) =>
      _repository.getOpenConsultations(petId);

  Future<ClinicalExam> request({
    required int consultationId,
    required ExamType type,
    String? indication,
  }) async => _store(
    await _repository.request(consultationId: consultationId, type: type, indication: indication),
  );

  Future<ClinicalExam> start(int examId) async => _store(await _repository.start(examId));

  Future<ClinicalExam> registerResult(int examId, ExamResultDraft draft) async =>
      _store(await _repository.registerResult(examId, draft));

  Future<ClinicalExam> validateResult(int examId) async =>
      _store(await _repository.validateResult(examId));

  Future<ClinicalExam> complete(int examId) async => _store(await _repository.complete(examId));

  Future<ClinicalExam> cancel(int examId, String reason) async =>
      _store(await _repository.cancel(examId, reason));

  Future<ClinicalExam> uploadFile(ClinicalExam exam, PickedImage image) async {
    final file = await _repository.uploadFile(exam.id, image);
    _fileBytes[file.id] = image.bytes;
    return _store((cached(exam.id) ?? exam).withFile(file));
  }

  Future<Uint8List> fileBytes(int examId, int fileId) async =>
      _fileBytes[fileId] ??= await _repository.downloadFile(examId, fileId);

  void clear() {
    _byPet.clear();
    _byId.clear();
    _errors.clear();
    _fileBytes.clear();
    notifyListeners();
  }

  ClinicalExam _store(ClinicalExam exam) {
    _byId[exam.id] = exam;
    final exams = _byPet[exam.petId];
    if (exams != null) {
      _byPet[exam.petId] = _sorted([
        for (final current in exams)
          if (current.id != exam.id) current,
        exam,
      ]);
    }
    notifyListeners();
    return exam;
  }

  static List<ClinicalExam> _sorted(List<ClinicalExam> exams) =>
      [...exams]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
}
