import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../domain/model/commands/add_clinical_finding_command.dart';
import '../../domain/model/value_objects/body_system.dart';
import '../../domain/model/value_objects/clinical_field_limits.dart';
import '../../domain/model/value_objects/finding_severity.dart';
import 'clinical_form_sheet.dart';
import 'clinical_text_field.dart';
import '../form_validation.dart';

/// Formulario de un hallazgo clínico.
class FindingFormSheet extends StatefulWidget {
  const FindingFormSheet({super.key, required this.consultationId, required this.onSubmit});

  final int consultationId;
  final Future<bool> Function(AddClinicalFindingCommand Function() build) onSubmit;

  @override
  State<FindingFormSheet> createState() => _FindingFormSheetState();
}

class _FindingFormSheetState extends State<FindingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  BodySystem? _bodySystem;
  FindingSeverity? _severity;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    if (!validateAndReveal(_formKey)) return false;
    return widget.onSubmit(
      () => AddClinicalFindingCommand(
        consultationId: widget.consultationId,
        bodySystem: _bodySystem!,
        description: _description.text,
        severity: _severity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalFormSheet(
      title: 'Agregar hallazgo',
      subtitle: 'Lo observado en un sistema del cuerpo',
      submitLabel: 'Agregar hallazgo',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        // El error desaparece apenas se corrige.
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'Sistema *',
              child: DropdownButtonFormField<BodySystem>(
                key: const Key('finding.bodySystem'),
                initialValue: _bodySystem,
                isExpanded: true,
                hint: const Text('Selecciona el sistema'),
                items: [
                  for (final system in BodySystem.values)
                    DropdownMenuItem(value: system, child: Text(system.label)),
                ],
                onChanged: (value) => _bodySystem = value,
                validator: (value) => value == null ? 'Selecciona el sistema.' : null,
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Severidad',
              hint: 'Opcional',
              child: Wrap(
                spacing: 8,
                children: [
                  for (final severity in FindingSeverity.values)
                    ChoiceChip(
                      label: Text(severity.label),
                      selected: _severity == severity,
                      onSelected: (selected) =>
                          setState(() => _severity = selected ? severity : null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClinicalTextField(
              fieldKey: const Key('finding.description'),
              label: 'Descripción',
              controller: _description,
              maxLength: ClinicalFieldLimits.findingDescription,
              requiredMessage: 'Describe el hallazgo.',
              minLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
