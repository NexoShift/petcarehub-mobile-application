import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/value_objects/clinical_field_limits.dart';

/// Pide el motivo de la cancelación. Devuelve null si el usuario vuelve atrás.
Future<String?> showCancelConsultationDialog(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _CancelConsultationDialog());

class _CancelConsultationDialog extends StatefulWidget {
  const _CancelConsultationDialog();

  @override
  State<_CancelConsultationDialog> createState() => _CancelConsultationDialogState();
}

class _CancelConsultationDialogState extends State<_CancelConsultationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState!.validate()) Navigator.of(context).pop(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar consulta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'La consulta quedará cancelada y no se podrá reabrir. Los datos ya registrados se conservan.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('cancel.reason'),
                controller: _reason,
                minLines: 2,
                maxLines: 4,
                maxLength: ClinicalFieldLimits.cancellationReason,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Motivo de la cancelación'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'El motivo es obligatorio.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
        TextButton(
          key: const Key('cancel.confirm'),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: _confirm,
          child: const Text('Cancelar consulta'),
        ),
      ],
    );
  }
}
