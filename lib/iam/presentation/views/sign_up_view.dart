import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../profiles/application/profiles_store.dart';
import '../../../profiles/domain/model/profile_draft.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/validators.dart';
import '../../../shared/presentation/widgets/brand_app_bar.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/iam_store.dart';
import '../../domain/model/account_type.dart';
import '../../domain/model/password_strength.dart';
import '../auth_error_messages.dart';
import '../widgets/account_type_card.dart';
import '../widgets/password_field.dart';
import '../widgets/password_strength_bar.dart';

/// MM-03 Registro de Usuario (paso 1 de 2: credenciales).
///
/// IAM solo guarda correo, contraseña y tipo de cuenta. El nombre y el teléfono
/// se guardan como [ProfileDraft] y prellenan el paso 2 (Profiles).
class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  AccountType _accountType = AccountType.petOwner;
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (_loading || !formOk || !_acceptedTerms) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    // Se guarda antes del sign-up porque, al quedar autenticado, el router
    // salta al paso 2 y ese paso lee el borrador.
    context.read<ProfilesStore>().draft = ProfileDraft(
      fullName: _fullName.text,
      phoneNumber: FormValidators.toApiPhone(_phone.text),
    );

    try {
      await context.read<IamStore>().signUp(
        email: _email.text,
        password: _password.text,
        accountType: _accountType,
      );
    } catch (error) {
      if (mounted) setState(() => _error = AuthErrorMessages.signUp(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Crea una contraseña';
    if (password.length < PasswordStrength.minLength) return 'Mínimo 8 caracteres';
    if (password.length > PasswordStrength.maxLength) return 'Máximo 72 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: BrandAppBar(onBack: () => context.go(AppRoutes.welcome)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _StepChip('Paso 1 de 2: Credenciales')),
                  const SizedBox(height: 12),
                  Text(
                    'Crear Cuenta',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Únete a la red veterinaria colaborativa',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Selecciona tu perfil',
                    hint: 'Configuración personalizada',
                    child: Column(
                      children: [
                        AccountTypeCard(
                          key: const Key('signUp.type.petOwner'),
                          icon: Icons.pets,
                          title: 'Dueño de Mascota',
                          badge: 'TUTOR',
                          description: 'Accede al historial de tus mascotas y resúmenes con IA',
                          selected: _accountType == AccountType.petOwner,
                          onTap: () => setState(() => _accountType = AccountType.petOwner),
                        ),
                        const SizedBox(height: 12),
                        AccountTypeCard(
                          key: const Key('signUp.type.clinic'),
                          icon: Icons.medical_services_outlined,
                          title: 'Médico Veterinario',
                          badge: 'CLÍNICO',
                          description:
                              'Registra consultas, prescribe y utiliza asistencia diagnóstica',
                          selected: _accountType == AccountType.clinic,
                          onTap: () => setState(() => _accountType = AccountType.clinic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LabeledField(
                    label: 'Nombre y Apellidos',
                    hint: 'Obligatorio',
                    child: TextFormField(
                      key: const Key('signUp.fullName'),
                      controller: _fullName,
                      validator: (v) => FormValidators.required(v, 'Ingresa tu nombre y apellidos'),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        hintText: 'Roberto García',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Correo electrónico',
                    hint: 'Para notificaciones y acceso',
                    child: TextFormField(
                      key: const Key('signUp.email'),
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
                    label: 'Teléfono móvil',
                    hint: 'Alertas de triaje médico',
                    child: TextFormField(
                      key: const Key('signUp.phone'),
                      controller: _phone,
                      validator: FormValidators.optionalPeruvianMobile,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      decoration: const InputDecoration(
                        hintText: '987 654 321',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+51 ',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Contraseña',
                    hint: 'Mínimo 8 caracteres',
                    child: PasswordField(
                      key: const Key('signUp.password'),
                      controller: _password,
                      validator: _validatePassword,
                      onChanged: (_) => setState(() {}),
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PasswordStrengthBar(password: _password.text),
                  const SizedBox(height: 16),
                  _TermsCheckbox(
                    value: _acceptedTerms,
                    showError: _termsError,
                    onChanged: (value) => setState(() {
                      _acceptedTerms = value;
                      if (value) _termsError = false;
                    }),
                  ),
                  if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    key: const Key('signUp.submit'),
                    label: 'Continuar al Perfil',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('¿Ya tienes cuenta?', style: text.bodySmall),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.signIn),
                        child: const Text('Iniciar Sesión'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ConnectedCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.turquoiseSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets, size: 12, color: AppColors.turquoise),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.deepBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.showError, required this.onChanged});

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const Key('signUp.terms'),
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.turquoise,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text.rich(
                    TextSpan(
                      style: small,
                      children: const [
                        TextSpan(text: 'Acepto los '),
                        TextSpan(
                          text: 'Términos de Servicio',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: AppColors.navy,
                          ),
                        ),
                        TextSpan(text: ' y la '),
                        TextSpan(
                          text: 'Política de Privacidad',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: AppColors.navy,
                          ),
                        ),
                        TextSpan(text: ' de Datos Clínicos y Bienestar Animal.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'Debes aceptar los términos para continuar',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard();

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.turquoiseSoft,
            child: Icon(Icons.pets, color: AppColors.turquoise),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PETCARE CONECTADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.turquoise,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Historial clínico y carnet digital unificado',
                  style: small?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                Text(
                  'Sincronizado con consultorios y clínicas aliadas',
                  style: small?.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
