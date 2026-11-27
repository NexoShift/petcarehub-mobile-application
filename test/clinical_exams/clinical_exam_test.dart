import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_result_draft.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_status.dart';

import '../support/clinical_exams_fakes.dart';

void main() {
  group('ClinicalExam', () {
    test('a requested exam can only be started or cancelled', () {
      final exam = clinicalExam();
      expect(exam.canStart, isTrue);
      expect(exam.canCancel, isTrue);
      expect(exam.canRegisterResult, isFalse);
      expect(exam.canAttachFiles, isFalse);
    });

    test('in process: register, then validate, then complete', () {
      final noResult = clinicalExam(status: ExamStatus.inProcess);
      expect(noResult.canRegisterResult, isTrue);
      expect(noResult.canValidateResult, isFalse);
      expect(noResult.canComplete, isFalse);
      expect(noResult.canAttachFiles, isTrue);

      final draft = clinicalExam(status: ExamStatus.inProcess, result: examResult());
      expect(draft.canRegisterResult, isFalse);
      expect(draft.canValidateResult, isTrue);
      expect(draft.canComplete, isFalse);

      final validated = clinicalExam(
        status: ExamStatus.inProcess,
        result: examResult(validated: true),
      );
      expect(validated.canValidateResult, isFalse);
      expect(validated.canComplete, isTrue);
      expect(validated.hasValidatedResult, isTrue);
    });

    test('completed and cancelled exams cannot change state', () {
      for (final status in [ExamStatus.completed, ExamStatus.cancelled]) {
        final exam = clinicalExam(status: status, result: examResult(validated: true));
        expect(exam.canStart, isFalse);
        expect(exam.canCancel, isFalse);
        expect(exam.canComplete, isFalse);
      }
      expect(clinicalExam(status: ExamStatus.completed).canAttachFiles, isTrue);
      expect(clinicalExam(status: ExamStatus.cancelled).canAttachFiles, isFalse);
    });

    test('unknown status from the API falls back to requested', () {
      expect(ExamStatus.fromApi('SOMETHING'), ExamStatus.requested);
      expect(ExamStatus.fromApi('IN_PROCESS'), ExamStatus.inProcess);
    });
  });

  group('ExamResultDraft', () {
    test('trims the texts and turns blanks into null', () {
      final draft = ExamResultDraft(
        summary: '  Normal  ',
        values: '   ',
        interpretation: ' Sin hallazgos ',
        resultDate: DateTime(2026, 9, 12),
        today: DateTime(2026, 9, 12),
      );
      expect(draft.summary, 'Normal');
      expect(draft.values, isNull);
      expect(draft.interpretation, 'Sin hallazgos');
    });

    test('rejects an empty summary and a future date', () {
      expect(
        () => ExamResultDraft(summary: ' ', resultDate: DateTime(2026, 9, 12)),
        throwsArgumentError,
      );
      expect(
        () => ExamResultDraft(
          summary: 'Normal',
          resultDate: DateTime(2026, 9, 13),
          today: DateTime(2026, 9, 12, 23),
        ),
        throwsArgumentError,
      );
    });

    test('rejects texts longer than the backend limits', () {
      expect(
        () => ExamResultDraft(
          summary: 'a' * (ExamResultDraft.maxSummary + 1),
          resultDate: DateTime(2026, 9, 12),
        ),
        throwsArgumentError,
      );
    });
  });
}
