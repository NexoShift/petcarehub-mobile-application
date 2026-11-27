import '../value_objects/body_system.dart';
import '../value_objects/clinical_field_limits.dart';
import '../value_objects/finding_severity.dart';
import 'command_validation.dart';

/// Agrega un hallazgo por sistema del cuerpo.
class AddClinicalFindingCommand {
  AddClinicalFindingCommand({
    required int consultationId,
    required this.bodySystem,
    required String description,
    this.severity,
  }) : consultationId = CommandValidation.requireId(consultationId),
       description = CommandValidation.requireText(
         description,
         ClinicalFieldLimits.findingDescription,
       );

  final int consultationId;
  final BodySystem bodySystem;
  final String description;
  final FindingSeverity? severity;
}
