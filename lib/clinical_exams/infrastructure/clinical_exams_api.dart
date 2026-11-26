import 'dart:typed_data';

import '../../shared/domain/picked_image.dart';
import '../../shared/infrastructure/api_client.dart';
import '../domain/model/clinical_exam.dart';
import '../domain/model/clinical_file.dart';
import '../domain/model/clinical_file_type.dart';
import '../domain/model/exam_result.dart';
import '../domain/model/exam_result_draft.dart';
import '../domain/model/exam_status.dart';
import '../domain/model/exam_type.dart';
import '../domain/model/open_consultation.dart';
import '../domain/repositories/clinical_exams_repository.dart';

class ClinicalExamsApi implements ClinicalExamsRepository {
  ClinicalExamsApi(this._client);

  final ApiClient _client;

  static const _exams = '/clinical-exams';

  @override
  Future<List<ClinicalExam>> getByPet(int petId) async =>
      ClinicalExamAssembler.fromJsonList(await _client.get('/pets/$petId/clinical-exams'));

  @override
  Future<ClinicalExam> getById(int examId) async =>
      ClinicalExamAssembler.fromJson(await _client.get('$_exams/$examId'));

  @override
  Future<List<OpenConsultation>> getOpenConsultations(int petId) async {
    final json = await _client.get('/pets/$petId/clinical-consultations') as List? ?? const [];
    return [
      for (final item in json.cast<Map<String, dynamic>>())
        if (item['status'] == 'IN_PROGRESS')
          OpenConsultation(
            id: (item['id'] as num).toInt(),
            reason: item['reason'] as String? ?? '',
            createdAt: DateTime.tryParse(item['createdAt'] as String? ?? '') ?? DateTime.now(),
          ),
    ];
  }

  @override
  Future<ClinicalExam> request({
    required int consultationId,
    required ExamType type,
    String? indication,
  }) async => ClinicalExamAssembler.fromJson(
    await _client.post(
      _exams,
      body: {
        'consultationId': consultationId,
        'type': type.apiValue,
        'indication': indication == null || indication.trim().isEmpty ? null : indication.trim(),
      },
    ),
  );

  @override
  Future<ClinicalExam> start(int examId) => _put('$_exams/$examId/start');

  @override
  Future<ClinicalExam> registerResult(int examId, ExamResultDraft draft) async =>
      ClinicalExamAssembler.fromJson(
        await _client.post(
          '$_exams/$examId/result',
          body: {
            'summary': draft.summary,
            'values': draft.values,
            'interpretation': draft.interpretation,
            'resultDate': ClinicalExamAssembler.toLocalDate(draft.resultDate),
          },
        ),
      );

  @override
  Future<ClinicalExam> validateResult(int examId) => _put('$_exams/$examId/result/validate');

  @override
  Future<ClinicalExam> complete(int examId) => _put('$_exams/$examId/complete');

  @override
  Future<ClinicalExam> cancel(int examId, String reason) =>
      _put('$_exams/$examId/cancel', body: {'reason': reason.trim()});

  @override
  Future<ClinicalFile> uploadFile(int examId, PickedImage image) async =>
      ClinicalExamAssembler.fileFromJson(
        await _client.postMultipart('$_exams/$examId/files', const {}, files: {'file': image}),
      );

  @override
  Future<Uint8List> downloadFile(int examId, int fileId) =>
      _client.getBytes('$_exams/$examId/files/$fileId');

  Future<ClinicalExam> _put(String path, {Object? body}) async =>
      ClinicalExamAssembler.fromJson(await _client.put(path, body: body));
}

/// Translates ClinicalExamResource and its nested resources into the domain model.
class ClinicalExamAssembler {
  const ClinicalExamAssembler._();

  static List<ClinicalExam> fromJsonList(dynamic json) => [
    for (final item in (json as List? ?? const []).cast<Map<String, dynamic>>()) fromJson(item),
  ];

  static ClinicalExam fromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>?;
    return ClinicalExam(
      id: _int(json['id']),
      consultationId: _int(json['consultationId']),
      clinicId: _int(json['clinicId']),
      petId: _int(json['petId']),
      requestedBy: _int(json['requestedBy']),
      type: ExamType.fromApi(json['type'] as String?),
      status: ExamStatus.fromApi(json['status'] as String?),
      indication: json['indication'] as String?,
      requestedAt: _date(json['requestedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      startedAt: _date(json['startedAt']),
      completedAt: _date(json['completedAt']),
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt: _date(json['cancelledAt']),
      result: result == null ? null : resultFromJson(result),
      files: [
        for (final file in (json['files'] as List? ?? const []).cast<Map<String, dynamic>>())
          fileFromJson(file),
      ],
    );
  }

  static ExamResult resultFromJson(Map<String, dynamic> json) => ExamResult(
    id: _int(json['id']),
    summary: json['summary'] as String? ?? '',
    values: json['values'] as String?,
    interpretation: json['interpretation'] as String?,
    resultDate: _date(json['resultDate']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    validated: json['validated'] as bool? ?? false,
    validatedBy: (json['validatedBy'] as num?)?.toInt(),
    validatedAt: _date(json['validatedAt']),
  );

  static ClinicalFile fileFromJson(dynamic data) {
    final json = data as Map<String, dynamic>;
    return ClinicalFile(
      id: _int(json['id']),
      fileName: json['fileName'] as String? ?? 'archivo',
      type: ClinicalFileType.fromApi(json['type'] as String?),
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: _int(json['sizeBytes']),
      uploadedAt: _date(json['uploadedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String toLocalDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

  static DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value) : null;
}
