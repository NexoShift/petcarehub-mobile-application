import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/clinical_file_type.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_result_draft.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_status.dart';
import 'package:petcare_mobile_application/clinical_exams/domain/model/exam_type.dart';
import 'package:petcare_mobile_application/clinical_exams/infrastructure/clinical_exams_api.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';
import 'package:petcare_mobile_application/shared/infrastructure/api_client.dart';

import '../support/fakes.dart';

void main() {
  ClinicalExamsApi apiWith(MockClientHandler handler) => ClinicalExamsApi(
    ApiClient(
      baseUrl: 'http://api.test/api/v1',
      tokenProvider: InMemorySessionStorage(),
      httpClient: MockClient(handler),
    ),
  );

  const examJson = {
    'id': 4,
    'consultationId': 9,
    'clinicId': 5,
    'petId': 1,
    'requestedBy': 7,
    'type': 'LABORATORY',
    'indication': 'Perfil bioquímico',
    'status': 'IN_PROCESS',
    'requestedAt': '2026-09-12T14:00:00Z',
    'startedAt': '2026-09-12T15:00:00Z',
    'completedAt': null,
    'cancellationReason': null,
    'cancelledAt': null,
    'result': {
      'id': 3,
      'summary': 'Normal',
      'values': 'ALT: 42 U/L',
      'interpretation': null,
      'resultDate': '2026-09-12',
      'validated': true,
      'validatedBy': 7,
      'validatedAt': '2026-09-13T10:00:00Z',
    },
    'files': [
      {
        'id': 11,
        'fileName': 'rx.png',
        'type': 'IMAGE',
        'contentType': 'image/png',
        'sizeBytes': 2048,
        'uploadedAt': '2026-09-12T16:00:00Z',
      },
    ],
  };

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  test('the assembler maps the resource with its result and files', () {
    final exam = ClinicalExamAssembler.fromJson(examJson);
    expect(exam.type, ExamType.laboratory);
    expect(exam.status, ExamStatus.inProcess);
    expect(exam.startedAt, DateTime.utc(2026, 9, 12, 15));
    expect(exam.result!.validated, isTrue);
    expect(exam.result!.resultDate, DateTime(2026, 9, 12));
    expect(exam.files.single.type, ClinicalFileType.image);
    expect(exam.files.single.sizeBytes, 2048);
    expect(exam.canComplete, isTrue);
  });

  test('lists the exams of a pet', () async {
    final api = apiWith((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/pets/1/clinical-exams');
      return json([examJson]);
    });
    expect((await api.getByPet(1)).single.id, 4);
  });

  test('request sends consultation, type and indication', () async {
    final api = apiWith((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/clinical-exams');
      expect(jsonDecode(request.body), {
        'consultationId': 9,
        'type': 'RADIOGRAPHY',
        'indication': 'Descartar fractura',
      });
      return json(examJson, 201);
    });
    await api.request(
      consultationId: 9,
      type: ExamType.radiography,
      indication: ' Descartar fractura ',
    );
  });

  test('state transitions use PUT on their sub-resource', () async {
    final paths = <String>[];
    final api = apiWith((request) async {
      expect(request.method, 'PUT');
      paths.add(request.url.path);
      if (request.url.path.endsWith('/cancel')) {
        expect(jsonDecode(request.body), {'reason': 'Tutor desistió'});
      }
      return json(examJson);
    });
    await api.start(4);
    await api.validateResult(4);
    await api.complete(4);
    await api.cancel(4, ' Tutor desistió ');
    expect(paths, [
      '/api/v1/clinical-exams/4/start',
      '/api/v1/clinical-exams/4/result/validate',
      '/api/v1/clinical-exams/4/complete',
      '/api/v1/clinical-exams/4/cancel',
    ]);
  });

  test('register result sends resultDate as LocalDate', () async {
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/clinical-exams/4/result');
      expect(jsonDecode(request.body), {
        'summary': 'Normal',
        'values': null,
        'interpretation': null,
        'resultDate': '2026-09-05',
      });
      return json(examJson, 201);
    });
    await api.registerResult(
      4,
      ExamResultDraft(summary: 'Normal', resultDate: DateTime(2026, 9, 5)),
    );
  });

  test('upload sends the photo as the "file" part', () async {
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/clinical-exams/4/files');
      final body = utf8.decode(request.bodyBytes, allowMalformed: true);
      expect(body, contains('name="file"; filename="foto.jpg"'));
      return json((examJson['files'] as List).first as Object, 201);
    });
    final file = await api.uploadFile(4, fakeImage());
    expect(file.id, 11);
  });

  test('download returns the raw bytes and errors become ApiError', () async {
    final api = apiWith((request) async {
      if (request.url.path.endsWith('/files/11')) {
        return http.Response.bytes([1, 2, 3], 200, headers: {'content-type': 'image/png'});
      }
      return json({'message': 'File not found'}, 404);
    });
    expect(await api.downloadFile(4, 11), [1, 2, 3]);
    await expectLater(
      api.downloadFile(4, 12),
      throwsA(isA<ApiError>().having((e) => e.message, 'message', 'File not found')),
    );
  });

  test('open consultations keeps only the ones in progress', () async {
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/pets/1/clinical-consultations');
      return json([
        {'id': 1, 'reason': 'Control', 'status': 'COMPLETED', 'createdAt': '2026-09-01T10:00:00Z'},
        {'id': 2, 'reason': 'Cojera', 'status': 'IN_PROGRESS', 'createdAt': '2026-09-12T10:00:00Z'},
      ]);
    });
    final open = await api.getOpenConsultations(1);
    expect(open.map((c) => c.id), [2]);
    expect(open.single.reason, 'Cojera');
  });
}
