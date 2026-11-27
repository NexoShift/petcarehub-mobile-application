import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/commands/register_physiological_assessment_command.dart';
import '../../domain/model/value_objects/clinical_field_limits.dart';
import '../../domain/model/value_objects/hydration_status.dart';
import '../../domain/model/value_objects/vital_signs.dart';
import '../clinical_formatters.dart';
import 'assessment_summary.dart';
import 'clinical_action_button.dart';
import 'clinical_card.dart';
import 'clinical_text_field.dart';
import '../form_validation.dart';

/// Fase 2: evaluación fisiológica (MM-15). Cada medición se agrega al registro.
class AssessmentPanel extends StatelessWidget {
  const AssessmentPanel({
    super.key,
    required this.consultation,
    required this.saving,
    required this.onSubmit,
    required this.onDirty,
  });

  final ClinicalConsultation consultation;
  final bool saving;
  final ValueChanged<RegisterPhysiologicalAssessmentCommand Function()> onSubmit;
  final VoidCallback onDirty;

  @override
  Widget build(BuildContext context) {
    final assessments = consultation.physiologicalAssessments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClinicalCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Evaluación fisiológica',
          subtitle: 'Cada medición se agrega al registro',
          // Con una medición nueva, la clave cambia y el formulario vuelve vacío.
          child: _AssessmentForm(
            key: ValueKey('assessment-form-${assessments.length}'),
            consultationId: consultation.id,
            saving: saving,
            onSubmit: onSubmit,
            onDirty: onDirty,
          ),
        ),
        if (assessments.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClinicalCard(
            icon: Icons.fact_check_outlined,
            title: 'Mediciones registradas (${assessments.length})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, assessment) in assessments.reversed.indexed) ...[
                  if (index > 0) const Divider(height: 24),
                  AssessmentSummary(assessment: assessment),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AssessmentForm extends StatefulWidget {
  const _AssessmentForm({
    super.key,
    required this.consultationId,
    required this.saving,
    required this.onSubmit,
    required this.onDirty,
  });

  final int consultationId;
  final bool saving;
  final ValueChanged<RegisterPhysiologicalAssessmentCommand Function()> onSubmit;
  final VoidCallback onDirty;

  @override
  State<_AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends State<_AssessmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _temperature = TextEditingController();
  final _heartRate = TextEditingController();
  final _respiratoryRate = TextEditingController();
  final _capillaryRefill = TextEditingController();
  final _mucousMembranes = TextEditingController();
  final _observations = TextEditingController();
  int? _bodyCondition;
  HydrationStatus? _hydration;

  @override
  void dispose() {
    for (final controller in [
      _weight,
      _temperature,
      _heartRate,
      _respiratoryRate,
      _capillaryRefill,
      _mucousMembranes,
      _observations,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!validateAndReveal(_formKey)) return;
    widget.onSubmit(
      () => RegisterPhysiologicalAssessmentCommand(
        consultationId: widget.consultationId,
        vitalSigns: VitalSigns.measured(
          weightKg: ClinicalFormatters.parseDecimal(_weight.text) ?? 0,
          temperatureCelsius: ClinicalFormatters.parseDecimal(_temperature.text) ?? 0,
          heartRateBpm: ClinicalFormatters.parseInteger(_heartRate.text) ?? 0,
          respiratoryRateBpm: ClinicalFormatters.parseInteger(_respiratoryRate.text) ?? 0,
        ),
        bodyConditionScore: _bodyCondition,
        hydrationStatus: _hydration,
        mucousMembranes: _mucousMembranes.text,
        capillaryRefillTimeSeconds: ClinicalFormatters.parseDecimal(_capillaryRefill.text),
        observations: _observations.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      // El error desaparece apenas se corrige.
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      onChanged: widget.onDirty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Pair(
            ClinicalNumberField(
              fieldKey: const Key('assessment.weight'),
              label: 'Peso',
              unit: 'kg',
              decimal: true,
              controller: _weight,
              isValid: VitalSigns.isValidWeight,
              invalidMessage: 'Mayor que 0 y hasta 500 kg.',
            ),
            ClinicalNumberField(
              fieldKey: const Key('assessment.temperature'),
              label: 'Temperatura',
              unit: '°C',
              decimal: true,
              controller: _temperature,
              isValid: VitalSigns.isValidTemperature,
              invalidMessage: 'Entre 30 y 45 °C.',
            ),
          ),
          const SizedBox(height: 12),
          _Pair(
            ClinicalNumberField(
              fieldKey: const Key('assessment.heartRate'),
              label: 'Frec. cardíaca',
              unit: 'lpm',
              controller: _heartRate,
              isValid: (value) => VitalSigns.isValidHeartRate(value.toInt()),
              invalidMessage: 'Entero entre 1 y 600.',
            ),
            ClinicalNumberField(
              fieldKey: const Key('assessment.respiratoryRate'),
              label: 'Frec. resp.',
              unit: 'rpm',
              controller: _respiratoryRate,
              isValid: (value) => VitalSigns.isValidRespiratoryRate(value.toInt()),
              invalidMessage: 'Entero entre 1 y 300.',
            ),
          ),
          const SizedBox(height: 12),
          _Pair(
            LabeledField(
              label: 'Condición corporal',
              child: DropdownButtonFormField<int?>(
                initialValue: _bodyCondition,
                isExpanded: true,
                hint: const Text('1 a 9'),
                items: [
                  const DropdownMenuItem(child: Text('Sin registrar')),
                  for (
                    var score = VitalSignLimits.minBodyConditionScore;
                    score <= VitalSignLimits.maxBodyConditionScore;
                    score++
                  )
                    DropdownMenuItem(value: score, child: Text(_bodyConditionLabel(score))),
                ],
                onChanged: (value) => _bodyCondition = value,
              ),
            ),
            ClinicalNumberField(
              fieldKey: const Key('assessment.capillaryRefill'),
              label: 'Llenado capilar',
              unit: 's',
              decimal: true,
              required: false,
              controller: _capillaryRefill,
              isValid: VitalSigns.isValidCapillaryRefill,
              invalidMessage: 'Debe ser mayor que 0.',
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Hidratación',
            hint: 'Opcional',
            child: DropdownButtonFormField<HydrationStatus?>(
              initialValue: _hydration,
              isExpanded: true,
              hint: const Text('Sin registrar'),
              items: [
                const DropdownMenuItem(child: Text('Sin registrar')),
                for (final status in HydrationStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (value) => _hydration = value,
            ),
          ),
          const SizedBox(height: 12),
          ClinicalTextField(
            label: 'Mucosas',
            hintText: 'Ej. rosadas y húmedas',
            controller: _mucousMembranes,
            maxLength: ClinicalFieldLimits.mucousMembranes,
          ),
          const SizedBox(height: 4),
          ClinicalTextField(
            label: 'Observaciones',
            controller: _observations,
            maxLength: ClinicalFieldLimits.assessmentObservations,
            minLines: 2,
          ),
          const SizedBox(height: 8),
          ClinicalActionButton(
            key: const Key('assessment.submit'),
            label: 'Registrar medición',
            onPressed: widget.saving ? null : _submit,
          ),
        ],
      ),
    );
  }

  static String _bodyConditionLabel(int score) => switch (score) {
    VitalSignLimits.minBodyConditionScore => '1 · Muy delgado',
    5 => '5 · Ideal',
    VitalSignLimits.maxBodyConditionScore => '9 · Obeso',
    _ => '$score',
  };
}

class _Pair extends StatelessWidget {
  const _Pair(this.left, this.right);

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 12),
      Expanded(child: right),
    ],
  );
}
