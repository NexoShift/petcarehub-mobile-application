import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/domain/api_error.dart';
import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/clinical_exams_store.dart';
import '../../domain/model/clinical_exam.dart';
import '../../domain/model/exam_type.dart';
import '../../domain/model/open_consultation.dart';

/// Veterinarian requests an exam; the API only accepts it inside a consultation in progress.
Future<void> showRequestExamSheet(BuildContext context, {required int petId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider<ClinicalExamsStore>.value(
      value: context.read<ClinicalExamsStore>(),
      child: _RequestExamSheet(petId: petId),
    ),
  );
}

class _RequestExamSheet extends StatefulWidget {
  const _RequestExamSheet({required this.petId});

  final int petId;

  @override
  State<_RequestExamSheet> createState() => _RequestExamSheetState();
}

class _RequestExamSheetState extends State<_RequestExamSheet> {
  final _indication = TextEditingController();
  late final Future<List<OpenConsultation>> _consultations;
  int? _consultationId;
  ExamType? _type;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _consultations = context.read<ClinicalExamsStore>().openConsultationsOf(widget.petId).then((
      list,
    ) {
      if (list.length == 1 && mounted) setState(() => _consultationId = list.first.id);
      return list;
    });
  }

  @override
  void dispose() {
    _indication.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_consultationId == null || _type == null) {
      setState(() => _error = 'Elige la consulta y el tipo de examen.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ClinicalExamsStore>().request(
        consultationId: _consultationId!,
        type: _type!,
        indication: _indication.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Examen de ${_type!.label.toLowerCase()} solicitado')));
      Navigator.pop(context);
    } on ApiError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: FutureBuilder<List<OpenConsultation>>(
        future: _consultations,
        builder: (context, snapshot) {
          final consultations = snapshot.data;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Solicitar examen',
                  style: text.titleLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El examen queda vinculado a una consulta en curso del paciente.',
                  style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                if (snapshot.hasError)
                  ErrorBanner(
                    snapshot.error is ApiError
                        ? (snapshot.error as ApiError).message
                        : 'No se pudieron cargar las consultas.',
                  )
                else if (consultations == null)
                  const Center(child: CircularProgressIndicator())
                else if (consultations.isEmpty)
                  const ErrorBanner(
                    'El paciente no tiene una consulta en curso. Inicia una consulta para solicitar exámenes.',
                  )
                else ...[
                  LabeledField(
                    label: 'Consulta',
                    child: DropdownButtonFormField<int>(
                      key: const Key('exam.consultation'),
                      initialValue: _consultationId,
                      isExpanded: true,
                      hint: const Text('Elige la consulta'),
                      items: [
                        for (final c in consultations)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.reason.isEmpty ? 'Consulta' : c.reason} · '
                              '${Formatters.date(c.createdAt)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (id) => setState(() => _consultationId = id),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Tipo de examen',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in ExamType.values)
                          ChoiceChip(
                            key: Key('exam.type.${type.name}'),
                            label: Text(type.label),
                            selected: _type == type,
                            onSelected: (_) => setState(() => _type = type),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Indicación',
                    hint: 'Opcional',
                    child: TextField(
                      key: const Key('exam.indication'),
                      controller: _indication,
                      maxLines: 3,
                      maxLength: ClinicalExam.maxIndication,
                      decoration: const InputDecoration(
                        hintText: 'Ej.: descartar fractura en miembro anterior',
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
                const SizedBox(height: 16),
                PrimaryButton(
                  key: const Key('exam.submit'),
                  label: 'Solicitar examen',
                  showArrow: false,
                  loading: _loading,
                  onPressed: consultations == null || consultations.isEmpty ? null : _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
