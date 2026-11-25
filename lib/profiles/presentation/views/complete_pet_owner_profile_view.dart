import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../iam/application/iam_store.dart';
import '../../../shared/domain/api_error.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/validators.dart';
import '../../../shared/presentation/widgets/brand_app_bar.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/profiles_store.dart';
import '../../domain/model/person_sex.dart';
import 'onboarding_header.dart';

/// Paso 2 de 2 para el dueño: crea su perfil en Profiles (POST /pet-owners).
class CompletePetOwnerProfileView extends StatefulWidget {
  const CompletePetOwnerProfileView({super.key});

  @override
  State<CompletePetOwnerProfileView> createState() => _CompletePetOwnerProfileViewState();
}

class _CompletePetOwnerProfileViewState extends State<CompletePetOwnerProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  PersonSex? _sex;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = context.read<ProfilesStore>().draft;
    _firstName = TextEditingController(text: draft?.firstName);
    _lastName = TextEditingController(text: draft?.lastName);
    _phone = TextEditingController(text: FormValidators.fromApiPhone(draft?.phoneNumber));
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    final session = context.read<IamStore>().session;
    if (session == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ProfilesStore>().completePetOwner(
        session: session,
        firstName: _firstName.text,
        lastName: _lastName.text,
        phoneNumber: FormValidators.toApiPhone(_phone.text),
        sex: _sex,
      );
      // El router ve el perfil completo y pasa a /home.
    } on ApiError catch (error) {
      if (mounted) {
        setState(
          () => _error = error.isNetworkError
              ? error.message
              : error.isConflict
              ? 'Tu perfil ya estaba registrado.'
              : 'No se pudo guardar tu perfil: ${error.message}',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OnboardingHeader(
                  title: 'Completa tu perfil',
                  subtitle: 'Así tu veterinario sabrá quién es el tutor de tu mascota',
                ),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'Nombres',
                  hint: 'Obligatorio',
                  child: TextFormField(
                    key: const Key('owner.firstName'),
                    controller: _firstName,
                    validator: (v) => FormValidators.required(v, 'Ingresa tus nombres'),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Apellidos',
                  hint: 'Obligatorio',
                  child: TextFormField(
                    key: const Key('owner.lastName'),
                    controller: _lastName,
                    validator: (v) => FormValidators.required(v, 'Ingresa tus apellidos'),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Teléfono móvil',
                  hint: 'Opcional',
                  child: TextFormField(
                    controller: _phone,
                    validator: FormValidators.optionalPeruvianMobile,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined),
                      prefixText: '+51 ',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Sexo',
                  hint: 'Opcional',
                  child: SegmentedButton<PersonSex>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: [
                      for (final sex in PersonSex.values)
                        ButtonSegment(value: sex, label: Text(sex.label)),
                    ],
                    selected: {?_sex},
                    onSelectionChanged: (s) => setState(() => _sex = s.isEmpty ? null : s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.turquoiseSoft,
                      selectedForegroundColor: AppColors.navy,
                    ),
                  ),
                ),
                if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
                const SizedBox(height: 24),
                PrimaryButton(
                  key: const Key('owner.submit'),
                  label: 'Finalizar registro',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<IamStore>().signOut(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
