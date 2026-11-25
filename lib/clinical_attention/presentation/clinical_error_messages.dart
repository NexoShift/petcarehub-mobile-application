import '../domain/model/clinical_attention_exception.dart';

/// Texto en español de cada error de dominio.
String clinicalErrorMessage(ClinicalAttentionErrorCode code) => switch (code) {
  ClinicalAttentionErrorCode.invalidRequest => 'Revisa los datos ingresados.',
  ClinicalAttentionErrorCode.invalidVitalSigns => 'Revisa las constantes: peso hasta 500 kg, temperatura entre 30 y 45 °C y frecuencias mayores que 0.',
  ClinicalAttentionErrorCode.invalidCancellation => 'Indica el motivo de la cancelación.',
  ClinicalAttentionErrorCode.petNotFound => 'La mascota indicada no existe.',
  ClinicalAttentionErrorCode.consultationNotFound => 'La consulta no existe.',
  ClinicalAttentionErrorCode.invalidConsultationState =>
    'La consulta ya cambió de estado. Vuelve a cargarla.',
  ClinicalAttentionErrorCode.incompleteConsultation =>
    'Aún faltan datos para finalizar la consulta.',
  ClinicalAttentionErrorCode.diagnosisConflict => 'Ya existe un diagnóstico principal vigente o este diagnóstico ya fue reevaluado. Vuelve a cargar la consulta.',
  ClinicalAttentionErrorCode.notAllowed => 'No tienes permiso para esta consulta.',
  ClinicalAttentionErrorCode.sessionExpired => 'Tu sesión expiró. Vuelve a iniciar sesión.',
  ClinicalAttentionErrorCode.noConnection => 'No hay conexión con el servidor.',
  ClinicalAttentionErrorCode.unexpected => 'Ocurrió un error inesperado. Inténtalo otra vez.',
};
