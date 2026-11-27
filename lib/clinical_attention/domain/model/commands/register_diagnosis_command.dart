import 'command_validation.dart';
import 'diagnosis_content.dart';

/// Registra un diagnóstico (US02). Solo puede haber un principal vigente.
class RegisterDiagnosisCommand {
  RegisterDiagnosisCommand({
    required int consultationId,
    required this.content,
    required this.primary,
  }) : consultationId = CommandValidation.requireId(consultationId);

  final int consultationId;
  final DiagnosisContent content;
  final bool primary;
}
