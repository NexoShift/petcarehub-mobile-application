import '../clinical_attention_exception.dart';
import '../value_objects/clinical_field_limits.dart';
import 'command_validation.dart';

/// Cancela la consulta. El motivo es obligatorio.
class CancelClinicalConsultationCommand {
  CancelClinicalConsultationCommand({required int consultationId, required String reason})
    : consultationId = CommandValidation.requireId(consultationId),
      reason = _requireReason(reason);

  final int consultationId;
  final String reason;

  static String _requireReason(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > ClinicalFieldLimits.cancellationReason) {
      throw const ClinicalAttentionException(ClinicalAttentionErrorCode.invalidCancellation);
    }
    return trimmed;
  }
}
