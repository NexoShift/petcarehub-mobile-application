import '../value_objects/clinical_field_limits.dart';
import 'command_validation.dart';

/// La anamnesis se registra una vez por consulta y no se sobrescribe (CON-01).
class RegisterAnamnesisCommand {
  RegisterAnamnesisCommand({
    required int consultationId,
    required String chiefComplaint,
    required String evolutionTime,
    Iterable<String> symptoms = const [],
    String? diet,
    String? behavior,
    String? previousTreatments,
    String? ownerObservations,
  }) : consultationId = CommandValidation.requireId(consultationId),
       chiefComplaint = CommandValidation.requireText(
         chiefComplaint,
         ClinicalFieldLimits.chiefComplaint,
       ),
       evolutionTime = CommandValidation.requireText(
         evolutionTime,
         ClinicalFieldLimits.evolutionTime,
       ),
       symptoms = CommandValidation.cleanList(
         symptoms,
         maxItems: ClinicalFieldLimits.maxSymptoms,
         maxItemLength: ClinicalFieldLimits.symptom,
       ),
       diet = CommandValidation.optionalText(diet, ClinicalFieldLimits.diet),
       behavior = CommandValidation.optionalText(behavior, ClinicalFieldLimits.behavior),
       previousTreatments = CommandValidation.optionalText(
         previousTreatments,
         ClinicalFieldLimits.previousTreatments,
       ),
       ownerObservations = CommandValidation.optionalText(
         ownerObservations,
         ClinicalFieldLimits.ownerObservations,
       );

  final int consultationId;
  final String chiefComplaint;
  final String evolutionTime;
  final List<String> symptoms;
  final String? diet;
  final String? behavior;
  final String? previousTreatments;
  final String? ownerObservations;
}
