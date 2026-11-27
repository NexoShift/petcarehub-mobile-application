import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/status_chip.dart';
import '../../domain/model/aggregates/clinical_consultation.dart';
import '../../domain/model/commands/register_anamnesis_command.dart';
import '../../domain/model/value_objects/clinical_field_limits.dart';
import 'anamnesis_summary.dart';
import 'chip_list_field.dart';
import 'clinical_card.dart';
import 'clinical_text_field.dart';
import '../form_validation.dart';

/// Fase 1: anamnesis (MM-14). Una vez registrada se muestra de solo lectura.
class AnamnesisPanel extends StatefulWidget {
  const AnamnesisPanel({
    super.key,
    required this.consultation,
    required this.onSubmit,
    required this.onDirty,
  });

  final ClinicalConsultation consultation;
  final ValueChanged<RegisterAnamnesisCommand Function()> onSubmit;
  final VoidCallback onDirty;

  @override
  State<AnamnesisPanel> createState() => AnamnesisPanelState();
}

class AnamnesisPanelState extends State<AnamnesisPanel> {
  static const _evolutionOptions = [
    (label: 'Menos de 24 h', detail: 'Cuadro hiperagudo', icon: Icons.bolt_outlined),
    (label: '1 a 2 días', detail: 'Cuadro agudo', icon: Icons.schedule),
    (label: '3 a 5 días', detail: 'Cuadro subagudo', icon: Icons.timelapse),
    (label: '1 a 2 semanas', detail: 'Evolución moderada', icon: Icons.date_range_outlined),
    (label: 'Más de 1 mes', detail: 'Evolución crónica', icon: Icons.history),
    (label: _other, detail: 'Escríbelo', icon: Icons.edit_outlined),
  ];
  static const _other = 'Otro';

  static const _symptomSuggestions = [
    'Prurito / Lamido frecuente',
    'Eritema visible',
    'Claudicación leve',
    'Pérdida de apetito',
    'Secreción o exudado',
    'Inflamación / Edema',
    'Vómitos',
    'Diarrea',
    'Fiebre',
    'Tos',
    'Letargo',
  ];

  final _formKey = GlobalKey<FormState>();
  final _symptomsKey = GlobalKey<ChipListFieldState>();
  late final _chiefComplaint = TextEditingController(text: widget.consultation.reason);
  final _otherEvolution = TextEditingController();
  final _diet = TextEditingController();
  final _behavior = TextEditingController();
  final _previousTreatments = TextEditingController();
  final _ownerObservations = TextEditingController();
  String? _evolution;
  List<String> _symptoms = const [];

  @override
  void dispose() {
    for (final controller in [
      _chiefComplaint,
      _otherEvolution,
      _diet,
      _behavior,
      _previousTreatments,
      _ownerObservations,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Lo llama la barra inferior de la consulta ("Registrar anamnesis").
  void submit() {
    final symptoms = _symptomsKey.currentState?.commitPending() ?? _symptoms;
    if (!validateAndReveal(_formKey)) return;
    widget.onSubmit(
      () => RegisterAnamnesisCommand(
        consultationId: widget.consultation.id,
        chiefComplaint: _chiefComplaint.text,
        evolutionTime: _evolution == _other ? _otherEvolution.text : _evolution ?? '',
        symptoms: symptoms,
        diet: _diet.text,
        behavior: _behavior.text,
        previousTreatments: _previousTreatments.text,
        ownerObservations: _ownerObservations.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anamnesis = widget.consultation.anamnesis;
    if (anamnesis != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClinicalCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Anamnesis registrada',
            subtitle: 'Registro clínico: no se modifica',
            child: AnamnesisSummary(anamnesis: anamnesis),
          ),
        ],
      );
    }
    return Form(
      key: _formKey,
      // El error desaparece apenas se corrige.
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      onChanged: widget.onDirty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClinicalCard(
            icon: Icons.record_voice_over_outlined,
            title: 'Interrogatorio clínico',
            subtitle: 'Lo que refiere el tutor de la mascota',
            trailing: const StatusChip(label: 'Obligatorio', color: AppColors.danger),
            child: ClinicalTextField(
              fieldKey: const Key('anamnesis.chiefComplaint'),
              label: 'Motivo principal de la consulta',
              hintText: 'Con las palabras del tutor',
              controller: _chiefComplaint,
              maxLength: ClinicalFieldLimits.chiefComplaint,
              requiredMessage: 'Describe el motivo principal.',
              minLines: 3,
              maxLines: 6,
            ),
          ),
          const SizedBox(height: 12),
          _evolutionCard(),
          const SizedBox(height: 12),
          ClinicalCard(
            icon: Icons.sick_outlined,
            title: 'Síntomas y conducta observada',
            subtitle: 'Toca los frecuentes o escribe otros',
            child: ChipListField(
              key: _symptomsKey,
              inputKey: const Key('anamnesis.symptom'),
              values: _symptoms,
              suggestions: _symptomSuggestions,
              hintText: 'Otro síntoma',
              maxItems: ClinicalFieldLimits.maxSymptoms,
              maxItemLength: ClinicalFieldLimits.symptom,
              onChanged: (values) {
                setState(() => _symptoms = values);
                widget.onDirty();
              },
            ),
          ),
          const SizedBox(height: 12),
          ClinicalCard(
            icon: Icons.medication_outlined,
            title: 'Antecedentes y contexto',
            subtitle: 'Opcional, ayuda en el diagnóstico',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClinicalTextField(
                  fieldKey: const Key('anamnesis.previousTreatments'),
                  label: 'Tratamientos previos',
                  hintText: '¿Se administró algún fármaco o remedio casero?',
                  controller: _previousTreatments,
                  maxLength: ClinicalFieldLimits.previousTreatments,
                  minLines: 2,
                ),
                const SizedBox(height: 8),
                ClinicalTextField(
                  label: 'Alimentación',
                  controller: _diet,
                  maxLength: ClinicalFieldLimits.diet,
                ),
                const SizedBox(height: 8),
                ClinicalTextField(
                  label: 'Comportamiento',
                  controller: _behavior,
                  maxLength: ClinicalFieldLimits.behavior,
                ),
                const SizedBox(height: 8),
                ClinicalTextField(
                  label: 'Observaciones del tutor',
                  controller: _ownerObservations,
                  maxLength: ClinicalFieldLimits.ownerObservations,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const ClinicalNote(
            'La anamnesis se registra una sola vez y luego no se puede modificar.',
          ),
        ],
      ),
    );
  }

  Widget _evolutionCard() {
    return ClinicalCard(
      icon: Icons.timeline,
      title: 'Tiempo de evolución *',
      subtitle: 'Desde cuándo empezaron los signos',
      child: FormField<String>(
        validator: (_) => _evolution == null ? 'Indica hace cuánto empezó.' : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _evolutionOptions)
                      SizedBox(
                        width: width,
                        child: _EvolutionOption(
                          label: option.label,
                          detail: option.detail,
                          icon: option.icon,
                          selected: _evolution == option.label,
                          onTap: () {
                            setState(() => _evolution = option.label);
                            field.didChange(option.label);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            if (_evolution == _other) ...[
              const SizedBox(height: 12),
              LabeledField(
                label: 'Especifica el tiempo *',
                child: TextFormField(
                  key: const Key('anamnesis.otherEvolution'),
                  controller: _otherEvolution,
                  maxLength: ClinicalFieldLimits.evolutionTime,
                  decoration: const InputDecoration(hintText: 'Ej. 3 semanas'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Indica hace cuánto empezó.' : null,
                ),
              ),
            ],
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(field.errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvolutionOption extends StatelessWidget {
  const _EvolutionOption({
    required this.label,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.turquoiseSoft : AppColors.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.turquoise : AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.navy),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label,
                        style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, size: 16, color: AppColors.turquoise),
                  ],
                ),
                Text(detail, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
