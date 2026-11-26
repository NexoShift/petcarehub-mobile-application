import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/validators.dart';
import '../../domain/model/clinical_exam.dart';

/// Returns the cancellation reason, or null when the veterinarian closes the dialog.
Future<String?> showCancelExamDialog(BuildContext context) {
  return showDialog<String>(context: context, builder: (_) => const _CancelExamDialog());
}

class _CancelExamDialog extends StatefulWidget {
  const _CancelExamDialog();

  @override
  State<_CancelExamDialog> createState() => _CancelExamDialogState();
}

class _CancelExamDialogState extends State<_CancelExamDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar examen'),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const Key('cancel.reason'),
          controller: _reason,
          autofocus: true,
          maxLines: 3,
          maxLength: ClinicalExam.maxCancellationReason,
          decoration: const InputDecoration(hintText: 'Motivo de la cancelación'),
          validator: (v) => FormValidators.required(v, 'Indica el motivo'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
        FilledButton(
          key: const Key('cancel.confirm'),
          onPressed: () {
            if (_form.currentState!.validate()) Navigator.pop(context, _reason.text.trim());
          },
          child: const Text('Cancelar examen'),
        ),
      ],
    );
  }
}
