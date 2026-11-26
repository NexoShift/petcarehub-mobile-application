import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/domain/api_error.dart';
import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/validators.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/clinical_exams_store.dart';
import '../../domain/model/exam_result_draft.dart';

Future<void> showExamResultSheet(BuildContext context, {required int examId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider<ClinicalExamsStore>.value(
      value: context.read<ClinicalExamsStore>(),
      child: _ExamResultSheet(examId: examId),
    ),
  );
}

class _ExamResultSheet extends StatefulWidget {
  const _ExamResultSheet({required this.examId});

  final int examId;

  @override
  State<_ExamResultSheet> createState() => _ExamResultSheetState();
}

class _ExamResultSheetState extends State<_ExamResultSheet> {
  final _form = GlobalKey<FormState>();
  final _summary = TextEditingController();
  final _values = TextEditingController();
  final _interpretation = TextEditingController();
  DateTime _resultDate = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _summary.dispose();
    _values.dispose();
    _interpretation.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _resultDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _resultDate = picked);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ClinicalExamsStore>().registerResult(
        widget.examId,
        ExamResultDraft(
          summary: _summary.text,
          values: _values.text,
          interpretation: _interpretation.text,
          resultDate: _resultDate,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Resultado registrado. Falta validarlo.')));
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
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrar resultado',
                style: text.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Resumen',
                child: TextFormField(
                  key: const Key('result.summary'),
                  controller: _summary,
                  maxLines: 3,
                  maxLength: ExamResultDraft.maxSummary,
                  validator: (v) => FormValidators.required(v, 'Escribe el resumen del resultado'),
                ),
              ),
              const SizedBox(height: 8),
              LabeledField(
                label: 'Valores',
                hint: 'Opcional',
                child: TextFormField(
                  key: const Key('result.values'),
                  controller: _values,
                  maxLines: 4,
                  maxLength: ExamResultDraft.maxValues,
                  decoration: const InputDecoration(hintText: 'ALT: 42 U/L\nCreatinina: 1.1 mg/dL'),
                ),
              ),
              const SizedBox(height: 8),
              LabeledField(
                label: 'Interpretación',
                hint: 'Opcional',
                child: TextFormField(
                  key: const Key('result.interpretation'),
                  controller: _interpretation,
                  maxLines: 3,
                  maxLength: ExamResultDraft.maxInterpretation,
                ),
              ),
              const SizedBox(height: 8),
              LabeledField(
                label: 'Fecha del resultado',
                child: OutlinedButton.icon(
                  key: const Key('result.date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(Formatters.date(_resultDate)),
                ),
              ),
              if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
              const SizedBox(height: 16),
              PrimaryButton(
                key: const Key('result.submit'),
                label: 'Guardar resultado',
                showArrow: false,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
