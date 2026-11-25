import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/domain/api_error.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/validators.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/iam_store.dart';
import '../../domain/model/password_strength.dart';
import '../widgets/password_field.dart';
import '../widgets/password_strength_bar.dart';

/// Cambiar contraseña. Se usa en dos casos:
/// - obligatorio: el vet entra con la contraseña temporal que le dio la clínica
///   (`mustChangePassword`); el router no lo deja salir de aquí hasta cambiarla;
/// - opcional: desde "Mi perfil".
class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateNew(String? value) {
    final password = value ?? '';
    if (password.length < PasswordStrength.minLength) return 'Mínimo 8 caracteres';
    if (password.length > PasswordStrength.maxLength) return 'Máximo 72 caracteres';
    if (password == _current.text) return 'Debe ser distinta a la actual';
    return null;
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    final store = context.read<IamStore>();
    final forced = store.session?.mustChangePassword ?? false;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.changePassword(currentPassword: _current.text, newPassword: _new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada')),
      );
      // Si era obligatorio, el router redirige solo; si vino del perfil, volvemos.
      if (!forced && context.canPop()) context.pop();
    } on ApiError catch (error) {
      if (mounted) {
        setState(() => _error = error.isNetworkError
            ? error.message
            : error.status == 400
                ? 'La contraseña actual no es correcta.'
                : 'No se pudo cambiar la contraseña.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<IamStore>();
    final forced = store.session?.mustChangePassword ?? false;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !forced,
        title: const Text('Cambiar contraseña'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (forced) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.turquoiseSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tu clínica te dio una contraseña temporal. Crea una nueva para continuar.',
                      style: text.bodyMedium?.copyWith(color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                LabeledField(
                  label: forced ? 'Contraseña temporal' : 'Contraseña actual',
                  child: PasswordField(
                    key: const Key('changePassword.current'),
                    controller: _current,
                    textInputAction: TextInputAction.next,
                    validator: (v) => FormValidators.required(v, 'Ingresa tu contraseña actual'),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Nueva contraseña',
                  hint: 'Mínimo 8 caracteres',
                  child: PasswordField(
                    key: const Key('changePassword.new'),
                    controller: _new,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _validateNew,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                PasswordStrengthBar(password: _new.text),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Repite la nueva contraseña',
                  child: PasswordField(
                    key: const Key('changePassword.confirm'),
                    controller: _confirm,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => v == _new.text ? null : 'Las contraseñas no coinciden',
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
                const SizedBox(height: 24),
                PrimaryButton(
                  key: const Key('changePassword.submit'),
                  label: 'Guardar contraseña',
                  showArrow: false,
                  loading: _loading,
                  onPressed: _submit,
                ),
                if (forced) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<IamStore>().signOut(),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
