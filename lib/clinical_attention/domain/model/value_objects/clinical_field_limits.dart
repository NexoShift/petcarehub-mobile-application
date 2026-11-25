/// Longitudes máximas que acepta la API (espejo de ClinicalFieldLimits del backend).
abstract final class ClinicalFieldLimits {
  static const reason = 350;
  static const chiefComplaint = 350;
  static const evolutionTime = 100;
  static const symptom = 100;
  static const maxSymptoms = 20;
  static const diet = 500;
  static const behavior = 500;
  static const previousTreatments = 1000;
  static const ownerObservations = 1000;
  static const mucousMembranes = 100;
  static const assessmentObservations = 2000;
  static const findingDescription = 1000;
  static const diagnosisDescription = 500;
  static const differentialDiagnosis = 200;
  static const maxDifferentialDiagnoses = 10;
  static const rationale = 2000;
  static const cancellationReason = 500;
}

/// Rangos aceptados para las constantes fisiológicas.
abstract final class VitalSignLimits {
  static const maxWeightKg = 500.0;
  static const minTemperatureCelsius = 30.0;
  static const maxTemperatureCelsius = 45.0;
  static const maxHeartRateBpm = 600;
  static const maxRespiratoryRateBpm = 300;
  static const minBodyConditionScore = 1;
  static const maxBodyConditionScore = 9;
}
