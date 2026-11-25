import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/commands/register_diagnosis_command.dart';
import '../../domain/model/entities/diagnosis.dart';
import 'clinical_action_button.dart';
import 'clinical_card.dart';
import 'diagnosis_card.dart';
import 'diagnosis_form.dart';

/// Fase 5: diagnóstico (MM-18). Un diagnóstico no se edita: se reevalúa.
class DiagnosisPanel extends StatefulWidget {
  const DiagnosisPanel({
    super.key,
    required this.consultation,
    required this.saving,
    required this.onSubmit,
    required this.onAddSecondary,
    required this.onReevaluate,
    required this.onDirty,
  });

  final ClinicalConsultation consultation;
  final bool saving;
  final ValueChanged<RegisterDiagnosisCommand Function()> onSubmit;
  final VoidCallback onAddSecondary;
  final ValueChanged<Diagnosis> onReevaluate;
  final VoidCallback onDirty;

  @override
  State<DiagnosisPanel> createState() => _DiagnosisPanelState();
}

class _DiagnosisPanelState extends State<DiagnosisPanel> {
  GlobalKey<DiagnosisFormState> _formKey = GlobalKey();
  bool _primary = true;

  @override
  void didUpdateWidget(DiagnosisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Con un diagnóstico nuevo, el formulario vuelve vacío.
    if (oldWidget.consultation.diagnoses.length != widget.consultation.diagnoses.length) {
      _formKey = GlobalKey();
      _primary = true;
    }
  }

  void _submit() {
    final content = _formKey.currentState!.validate();
    if (content == null) return;
    final primary = _primary;
    widget.onSubmit(
      () => RegisterDiagnosisCommand(
        consultationId: widget.consultation.id,
        content: content(),
        primary: primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final diagnosis in consultation.currentDiagnoses) ...[
          DiagnosisCard(
            diagnosis: diagnosis,
            onReevaluate: widget.saving ? null : () => widget.onReevaluate(diagnosis),
          ),
          const SizedBox(height: 12),
        ],
        if (consultation.canRegisterPrimaryDiagnosis)
          ClinicalCard(
            icon: Icons.medical_services_outlined,
            title: 'Registrar diagnóstico',
            subtitle: 'Conclusión clínica de esta consulta',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DiagnosisForm(key: _formKey, onDirty: widget.onDirty),
                SwitchListTile(
                  key: const Key('diagnosis.primary'),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.turquoise,
                  title: const Text('Diagnóstico principal'),
                  subtitle: const Text('Se necesita uno para finalizar'),
                  value: _primary,
                  onChanged: (value) => setState(() => _primary = value),
                ),
                const SizedBox(height: 8),
                ClinicalActionButton(
                  key: const Key('diagnosis.submit'),
                  label: 'Registrar diagnóstico',
                  onPressed: widget.saving ? null : _submit,
                ),
              ],
            ),
          )
        else
          ClinicalActionButton(
            key: const Key('diagnosis.addSecondary'),
            label: 'Agregar diagnóstico secundario',
            onPressed: widget.saving ? null : widget.onAddSecondary,
          ),
        SupersededDiagnoses(diagnoses: consultation.supersededDiagnoses),
        const SizedBox(height: 12),
        const ClinicalNote(
          'Un diagnóstico no se edita: se reevalúa y el anterior queda en el historial.',
        ),
      ],
    );
  }
}
