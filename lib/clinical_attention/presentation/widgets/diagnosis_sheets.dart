import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/commands/reevaluate_diagnosis_command.dart';
import '../../domain/model/commands/register_diagnosis_command.dart';
import '../../domain/model/entities/diagnosis.dart';
import 'clinical_form_sheet.dart';
import 'diagnosis_form.dart';

/// Registra un diagnóstico secundario (ya hay uno principal vigente).
class SecondaryDiagnosisSheet extends StatefulWidget {
  const SecondaryDiagnosisSheet({super.key, required this.consultationId, required this.onSubmit});

  final int consultationId;
  final Future<bool> Function(RegisterDiagnosisCommand Function() build) onSubmit;

  @override
  State<SecondaryDiagnosisSheet> createState() => _SecondaryDiagnosisSheetState();
}

class _SecondaryDiagnosisSheetState extends State<SecondaryDiagnosisSheet> {
  final _formKey = GlobalKey<DiagnosisFormState>();

  Future<bool> _submit() async {
    final content = _formKey.currentState!.validate();
    if (content == null) return false;
    return widget.onSubmit(
      () => RegisterDiagnosisCommand(
        consultationId: widget.consultationId,
        content: content(),
        primary: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ClinicalFormSheet(
    title: 'Diagnóstico secundario',
    subtitle: 'El diagnóstico principal no cambia.',
    submitLabel: 'Registrar diagnóstico',
    onSubmit: _submit,
    child: DiagnosisForm(key: _formKey),
  );
}

/// Reevalúa un diagnóstico vigente: crea uno nuevo y conserva el anterior.
class ReevaluationSheet extends StatefulWidget {
  const ReevaluationSheet({
    super.key,
    required this.consultationId,
    required this.diagnosis,
    required this.onSubmit,
  });

  final int consultationId;
  final Diagnosis diagnosis;
  final Future<bool> Function(ReevaluateDiagnosisCommand Function() build) onSubmit;

  @override
  State<ReevaluationSheet> createState() => _ReevaluationSheetState();
}

class _ReevaluationSheetState extends State<ReevaluationSheet> {
  final _formKey = GlobalKey<DiagnosisFormState>();

  Future<bool> _submit() async {
    final content = _formKey.currentState!.validate();
    if (content == null) return false;
    return widget.onSubmit(
      () => ReevaluateDiagnosisCommand(
        consultationId: widget.consultationId,
        diagnosisId: widget.diagnosis.id,
        content: content(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ClinicalFormSheet(
    title: 'Reevaluar diagnóstico',
    subtitle: 'Se crea un diagnóstico nuevo; el actual queda como reemplazado y no se pierde.',
    submitLabel: 'Registrar reevaluación',
    onSubmit: _submit,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Actual: ${widget.diagnosis.description}'),
        ),
        const SizedBox(height: 16),
        DiagnosisForm(key: _formKey),
      ],
    ),
  );
}
