import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/consultation_workspace_store.dart';
import '../clinical_error_messages.dart';

/// Abre un formulario en una hoja inferior que se adapta al teclado.
Future<void> showClinicalFormSheet(BuildContext context, {required WidgetBuilder builder}) async {
  final store = context.read<ConsultationWorkspaceStore>()..clearError();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: builder,
  );
  store.clearError();
}

/// Título, campos, error y botón. Solo se cierra si la API aceptó el registro,
/// para no perder lo que el veterinario escribió.
class ClinicalFormSheet extends StatelessWidget {
  const ClinicalFormSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String submitLabel;

  /// Devuelve true si se registró.
  final Future<bool> Function() onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsultationWorkspaceStore>();
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: !store.isSaving,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
            ],
            const SizedBox(height: 16),
            child,
            if (store.error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(clinicalErrorMessage(store.error!)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              key: const Key('clinicalSheet.submit'),
              label: submitLabel,
              showArrow: false,
              loading: store.isSaving,
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (await onSubmit() && navigator.mounted) navigator.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
