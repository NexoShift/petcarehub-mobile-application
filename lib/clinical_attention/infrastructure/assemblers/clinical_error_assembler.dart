import '../../../shared/domain/api_error.dart';
import '../../domain/model/clinical_attention_exception.dart';
import '../../domain/model/value_objects/pending_item.dart';

/// Traduce un error HTTP a un error de dominio. Lo que significa un 404 o un
/// 409 depende de la operación que falló.
abstract final class ClinicalErrorAssembler {
  static ClinicalAttentionException fromApiError(
    ApiError error, {
    ClinicalAttentionErrorCode notFound = ClinicalAttentionErrorCode.consultationNotFound,
    ClinicalAttentionErrorCode conflict = ClinicalAttentionErrorCode.invalidConsultationState,
  }) => switch (error.status) {
    0 => const ClinicalAttentionException(ClinicalAttentionErrorCode.noConnection),
    400 => const ClinicalAttentionException(ClinicalAttentionErrorCode.invalidRequest),
    401 => const ClinicalAttentionException(ClinicalAttentionErrorCode.sessionExpired),
    403 => const ClinicalAttentionException(ClinicalAttentionErrorCode.notAllowed),
    404 => ClinicalAttentionException(notFound),
    409 => _conflict(conflict, error.details),
    _ => const ClinicalAttentionException(ClinicalAttentionErrorCode.unexpected),
  };

  /// Completar responde 409 con lo pendiente; sin detalle, la consulta cambió de estado.
  static ClinicalAttentionException _conflict(
    ClinicalAttentionErrorCode code,
    List<String> details,
  ) {
    if (code != ClinicalAttentionErrorCode.incompleteConsultation) {
      return ClinicalAttentionException(code);
    }
    if (details.isEmpty) {
      return const ClinicalAttentionException(ClinicalAttentionErrorCode.invalidConsultationState);
    }
    return ClinicalAttentionException(
      code,
      pendingItems: [for (final detail in details) ?PendingItem.fromApi(detail)],
    );
  }
}
