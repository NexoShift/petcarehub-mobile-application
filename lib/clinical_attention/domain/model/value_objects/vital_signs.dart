import '../clinical_attention_exception.dart';
import 'clinical_field_limits.dart';

/// Constantes vitales de una medición (VitalSigns del backend).
class VitalSigns {
  /// Constantes ya registradas: vienen de la API y no se vuelven a validar.
  const VitalSigns({
    required this.weightKg,
    required this.temperatureCelsius,
    required this.heartRateBpm,
    required this.respiratoryRateBpm,
  });

  /// Constantes que se acaban de tomar. Fuera de rango lanza
  /// [ClinicalAttentionErrorCode.invalidVitalSigns].
  factory VitalSigns.measured({
    required double weightKg,
    required double temperatureCelsius,
    required int heartRateBpm,
    required int respiratoryRateBpm,
  }) {
    final valid =
        isValidWeight(weightKg) &&
        isValidTemperature(temperatureCelsius) &&
        isValidHeartRate(heartRateBpm) &&
        isValidRespiratoryRate(respiratoryRateBpm);
    if (!valid) {
      throw const ClinicalAttentionException(ClinicalAttentionErrorCode.invalidVitalSigns);
    }
    return VitalSigns(
      weightKg: weightKg,
      temperatureCelsius: temperatureCelsius,
      heartRateBpm: heartRateBpm,
      respiratoryRateBpm: respiratoryRateBpm,
    );
  }

  final double weightKg;
  final double temperatureCelsius;
  final int heartRateBpm;
  final int respiratoryRateBpm;

  static bool isValidWeight(double value) =>
      value.isFinite && value > 0 && value <= VitalSignLimits.maxWeightKg;

  static bool isValidTemperature(double value) =>
      value >= VitalSignLimits.minTemperatureCelsius &&
      value <= VitalSignLimits.maxTemperatureCelsius;

  static bool isValidHeartRate(int value) => value > 0 && value <= VitalSignLimits.maxHeartRateBpm;

  static bool isValidRespiratoryRate(int value) =>
      value > 0 && value <= VitalSignLimits.maxRespiratoryRateBpm;

  static bool isValidBodyConditionScore(int value) =>
      value >= VitalSignLimits.minBodyConditionScore &&
      value <= VitalSignLimits.maxBodyConditionScore;

  static bool isValidCapillaryRefill(double value) => value.isFinite && value > 0;
}
