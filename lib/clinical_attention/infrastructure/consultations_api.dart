import '../../shared/infrastructure/api_client.dart';
import '../domain/model/consultation_status.dart';
import '../domain/model/consultation_summary.dart';
import '../domain/repositories/consultations_repository.dart';

/// GET /pets/{petId}/clinical-consultations (dueño o vet de una clínica donde es paciente).
class ConsultationsApi implements ConsultationsRepository {
  ConsultationsApi(this._client);

  final ApiClient _client;

  @override
  Future<List<ConsultationSummary>> getByPet(int petId) async {
    final json = await _client.get('/pets/$petId/clinical-consultations') as List? ?? const [];
    return [for (final item in json) ConsultationSummaryAssembler.fromJson(item as Map<String, dynamic>)];
  }
}

class ConsultationSummaryAssembler {
  const ConsultationSummaryAssembler._();

  static ConsultationSummary fromJson(Map<String, dynamic> json) {
    final diagnoses = (json['diagnoses'] as List? ?? const []).cast<Map<String, dynamic>>();
    final main = diagnoses.where((d) => d['primary'] == true).firstOrNull ?? diagnoses.firstOrNull;
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.tryParse(json[key] as String);
    return ConsultationSummary(
      id: (json['id'] as num).toInt(),
      petId: (json['petId'] as num).toInt(),
      clinicId: (json['clinicId'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      status: ConsultationStatus.fromApi(json['status'] as String?),
      createdAt: date('createdAt') ?? DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: date('completedAt'),
      mainDiagnosis: main?['description'] as String?,
    );
  }
}
