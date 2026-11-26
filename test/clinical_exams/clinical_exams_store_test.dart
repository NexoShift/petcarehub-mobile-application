import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_exams/application/clinical_exams_store.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_result_draft.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_status.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_type.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/open_consultation.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';

import '../support/clinical_exams_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeClinicalExamsRepository repository;
  late ClinicalExamsStore store;

  setUp(() {
    repository = FakeClinicalExamsRepository()
      ..add(clinicalExam(id: 1, requestedAt: DateTime(2026, 2, 2)))
      ..add(clinicalExam(id: 2, requestedAt: DateTime(2026, 9, 12)))
      ..add(clinicalExam(id: 3, petId: 2));
    store = ClinicalExamsStore(repository: repository);
  });

  test('loads the exams of a pet newest first and uses the cache', () async {
    await store.loadForPet(1);
    await store.loadForPet(1);

    expect(store.examsOf(1)!.map((e) => e.id), [2, 1]);
    expect(repository.calls.where((c) => c == 'getByPet'), hasLength(1));
  });

  test('full veterinarian flow updates the cached list', () async {
    await store.loadForPet(1);

    await store.start(2);
    await store.registerResult(
      2,
      ExamResultDraft(summary: 'Normal', resultDate: DateTime(2026, 9, 12)),
    );
    await store.validateResult(2);
    final exam = await store.complete(2);

    expect(exam.status, ExamStatus.completed);
    expect(store.examsOf(1)!.first.status, ExamStatus.completed);
    expect(store.cached(2)!.hasValidatedResult, isTrue);
  });

  test('an invalid transition keeps the exam unchanged and rethrows', () async {
    await store.loadForPet(1);
    await expectLater(store.complete(2), throwsA(isA<ApiError>()));
    expect(store.examsOf(1)!.first.status, ExamStatus.requested);
  });

  test('request adds the new exam to the pet list', () async {
    repository.openConsultations[1] = [
      OpenConsultation(id: 9, reason: 'Cojera', createdAt: DateTime(2026, 9, 15)),
    ];
    await store.loadForPet(1);

    await store.request(consultationId: 9, type: ExamType.radiography);

    expect(store.examsOf(1)!.first.type, ExamType.radiography);
    expect(store.examsOf(1), hasLength(3));
  });

  test('uploaded photos are added to the exam and their bytes are cached', () async {
    await store.loadForPet(1);
    final started = await store.start(1);

    final exam = await store.uploadFile(started, fakeImage(size: 4));
    await store.fileBytes(1, exam.files.single.id);

    expect(exam.files, hasLength(1));
    expect(store.cached(1)!.files, hasLength(1));
    expect(repository.calls, isNot(contains('downloadFile')));
  });

  test('clear removes every cached exam', () async {
    await store.loadForPet(1);
    store.clear();
    expect(store.examsOf(1), isNull);
    expect(store.cached(1), isNull);
  });
}
