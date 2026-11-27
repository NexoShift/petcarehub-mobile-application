import '../value_objects/clinical_field_limits.dart';
import '../value_objects/diagnosis_type.dart';
import 'command_validation.dart';

/// Datos comunes a registrar un diagnóstico y a reevaluarlo.
class DiagnosisContent {
  DiagnosisContent({
    required String description,
    required this.type,
    Iterable<String> differentialDiagnoses = const [],
    String? rationale,
  }) : description = CommandValidation.requireText(
         description,
         ClinicalFieldLimits.diagnosisDescription,
       ),
       differentialDiagnoses = CommandValidation.cleanList(
         differentialDiagnoses,
         maxItems: ClinicalFieldLimits.maxDifferentialDiagnoses,
         maxItemLength: ClinicalFieldLimits.differentialDiagnosis,
       ),
       rationale = CommandValidation.optionalText(rationale, ClinicalFieldLimits.rationale);

  final String description;
  final DiagnosisType type;
  final List<String> differentialDiagnoses;
  final String? rationale;
}
