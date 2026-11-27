import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../domain/model/commands/diagnosis_content.dart';
import '../../domain/model/value_objects/clinical_field_limits.dart';
import '../../domain/model/value_objects/diagnosis_type.dart';
import 'chip_list_field.dart';
import 'clinical_text_field.dart';
import '../form_validation.dart';

/// Campos de un diagnóstico. Los usan el registro y la reevaluación.
class DiagnosisForm extends StatefulWidget {
  const DiagnosisForm({super.key, this.onDirty});

  final VoidCallback? onDirty;

  @override
  State<DiagnosisForm> createState() => DiagnosisFormState();
}

class DiagnosisFormState extends State<DiagnosisForm> {
  final _formKey = GlobalKey<FormState>();
  final _differentialsKey = GlobalKey<ChipListFieldState>();
  final _description = TextEditingController();
  final _rationale = TextEditingController();
  DiagnosisType? _type;
  List<String> _differentials = const [];

  @override
  void dispose() {
    _description.dispose();
    _rationale.dispose();
    super.dispose();
  }

  /// Función que crea el contenido, o null si faltan datos.
  DiagnosisContent Function()? validate() {
    final differentials = _differentialsKey.currentState?.commitPending() ?? _differentials;
    if (!validateAndReveal(_formKey)) return null;
    return () => DiagnosisContent(
      description: _description.text,
      type: _type!,
      differentialDiagnoses: differentials,
      rationale: _rationale.text,
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
          FormField<DiagnosisType>(
            validator: (_) => _type == null ? 'Selecciona el tipo.' : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<DiagnosisType>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.turquoise,
                    selectedForegroundColor: AppColors.navy,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  segments: [
                    for (final type in DiagnosisType.values)
                      ButtonSegment(
                        value: type,
                        icon: Icon(
                          type == DiagnosisType.definitive
                              ? Icons.check_circle_outline
                              : Icons.help_outline,
                        ),
                        label: Text(type.label),
                      ),
                  ],
                  selected: {?_type},
                  onSelectionChanged: (selection) {
                    setState(() => _type = selection.firstOrNull);
                    field.didChange(_type);
                  },
                ),
                if (field.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    field.errorText!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClinicalTextField(
            fieldKey: const Key('diagnosis.description'),
            label: 'Diagnóstico clínico',
            controller: _description,
            maxLength: ClinicalFieldLimits.diagnosisDescription,
            requiredMessage: 'Describe el diagnóstico.',
            minLines: 2,
          ),
          const SizedBox(height: 4),
          LabeledField(
            label: 'Diagnósticos diferenciales',
            hint: 'Opcional',
            child: ChipListField(
              key: _differentialsKey,
              inputKey: const Key('diagnosis.differential'),
              values: _differentials,
              hintText: 'Agregar diferencial',
              maxItems: ClinicalFieldLimits.maxDifferentialDiagnoses,
              maxItemLength: ClinicalFieldLimits.differentialDiagnosis,
              onChanged: (values) {
                setState(() => _differentials = values);
                widget.onDirty?.call();
              },
            ),
          ),
          const SizedBox(height: 12),
          ClinicalTextField(
            fieldKey: const Key('diagnosis.rationale'),
            label: 'Fundamento clínico',
            controller: _rationale,
            maxLength: ClinicalFieldLimits.rationale,
            minLines: 3,
            maxLines: 6,
          ),
        ],
      ),
    );
  }
}
