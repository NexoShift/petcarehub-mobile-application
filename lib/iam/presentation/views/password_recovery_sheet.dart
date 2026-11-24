import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/domain/api_error.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/validators.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/iam_store.dart';

/// Hoja inferior "¿Olvidaste tu contraseña?". Envía el correo de recuperación;
/// el enlace del correo abre la pantalla de restablecer de la web.
Future<void> showPasswordRecoverySheet(BuildContext context, String initialEmail) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider<IamStore>.value(
      value: context.read<IamStore>(),
      child: _PasswordRecoverySheet(initialEmail: initialEmail),
    ),
  );
}

class _PasswordRecoverySheet extends StatefulWidget {
  const _PasswordRecoverySheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_PasswordRecoverySheet> createState() => _PasswordRecoverySheetState();
}

class _PasswordRecoverySheetState extends State<_PasswordRecoverySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<IamStore>().requestPasswordRecovery(_email.text);
      if (mounted) setState(() => _sent = true);
    } on ApiError catch (error) {
      if (mounted) {
        setState(
          () => _error = error.isNetworkError ? error.message : 'No se pudo enviar el correo.',
        );
      }
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
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recuperar contraseña',
              style: text.titleLarge?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_sent)
              Text(
                'Si el correo está registrado, te enviamos un enlace para crear una nueva contraseña. Revisa tu bandeja de entrada.',
                style: text.bodyMedium,
              )
            else ...[
              Text(
                'Te enviaremos un enlace a tu correo para crear una nueva contraseña.',
                style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                validator: FormValidators.email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'tu@correo.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Enviar enlace',
                showArrow: false,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
