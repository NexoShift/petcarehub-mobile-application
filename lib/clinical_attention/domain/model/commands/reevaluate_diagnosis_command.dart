import 'command_validation.dart';
import 'diagnosis_content.dart';

/// Reemplaza un diagnóstico vigente por uno nuevo. El anterior se conserva
/// como SUPERSEDED (CON-01).
class ReevaluateDiagnosisCommand {
  ReevaluateDiagnosisCommand({
    required int consultationId,
    required int diagnosisId,
    required this.content,
  }) : consultationId = CommandValidation.requireId(consultationId),
       diagnosisId = CommandValidation.requireId(diagnosisId);

  final int consultationId;
  final int diagnosisId;
  final DiagnosisContent content;
}
