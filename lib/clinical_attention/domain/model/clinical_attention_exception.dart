import 'value_objects/pending_item.dart';

/// Motivos por los que falla una operación de Clinical Attention. El texto que
/// ve el usuario está en presentation (clinical_error_messages.dart).
enum ClinicalAttentionErrorCode {
  invalidRequest,
  invalidVitalSigns,
  invalidCancellation,
  petNotFound,
  petNotPatient,
  consultationNotFound,
  invalidConsultationState,
  incompleteConsultation,
  diagnosisConflict,
  notAllowed,
  sessionExpired,
  noConnection,
  unexpected,
}

/// Error de dominio. Las vistas nunca ven un ApiError ni un http.Response.
class ClinicalAttentionException implements Exception {
  const ClinicalAttentionException(this.code, {this.pendingItems = const []});

  final ClinicalAttentionErrorCode code;

  /// Lo que falta cuando [code] es `incompleteConsultation`.
  final List<PendingItem> pendingItems;

  @override
  String toString() => 'ClinicalAttentionException(${code.name})';
}
