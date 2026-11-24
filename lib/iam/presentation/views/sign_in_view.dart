import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/validators.dart';
import '../../../shared/presentation/widgets/brand_app_bar.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/iam_store.dart';
import '../auth_error_messages.dart';
import '../widgets/password_field.dart';
import 'password_recovery_sheet.dart';

/// MM-02 Inicio de Sesión.
///
/// Sin pestañas Dueño/Médico: el rol viene en la respuesta del sign-in
/// (misma decisión que en la web). Al entrar, el router decide a dónde ir.
class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<IamStore>().signIn(email: _email.text, password: _password.text);
      // No navegamos aquí: el router escucha IamStore y redirige solo.
    } catch (error) {
      if (mounted) setState(() => _error = AuthErrorMessages.signIn(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: BrandAppBar(onBack: () => context.go(AppRoutes.welcome)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bienvenido de nuevo',
                    style: text.headlineSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ingresa para acceder a tus historiales clínicos',
                    style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  LabeledField(
                    label: 'Correo electrónico',
                    child: TextFormField(
                      key: const Key('signIn.email'),
                      controller: _email,
                      validator: FormValidators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'roberto.garcia@example.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Contraseña',
                    child: PasswordField(
                      key: const Key('signIn.password'),
                      controller: _password,
                      validator: (v) => FormValidators.required(v, 'Ingresa tu contraseña'),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.turquoise),
                      onPressed: () => showPasswordRecoverySheet(context, _email.text),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
                  const SizedBox(height: 8),
                  PrimaryButton(label: 'Iniciar Sesión', loading: _loading, onPressed: _submit),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('¿No tienes una cuenta?', style: text.bodySmall),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.signUp),
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
