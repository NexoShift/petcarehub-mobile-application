import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../iam/application/iam_store.dart';
import '../../../shared/domain/api_error.dart';
import '../../../shared/presentation/validators.dart';
import '../../../shared/presentation/widgets/brand_app_bar.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/labeled_field.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/profiles_store.dart';
import 'onboarding_header.dart';

/// Paso 2 de 2 para la cuenta clínica: crea la clínica (POST /clinics).
class CompleteClinicProfileView extends StatefulWidget {
  const CompleteClinicProfileView({super.key});

  @override
  State<CompleteClinicProfileView> createState() => _CompleteClinicProfileViewState();
}

class _CompleteClinicProfileViewState extends State<CompleteClinicProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ruc = TextEditingController();
  final _address = TextEditingController();
  late final TextEditingController _phone;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = context.read<ProfilesStore>().draft;
    _phone = TextEditingController(text: FormValidators.fromApiPhone(draft?.phoneNumber));
  }

  @override
  void dispose() {
    _name.dispose();
    _ruc.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validateRuc(String? value) {
    final ruc = (value ?? '').trim();
    if (ruc.isEmpty) return null;
    return RegExp(r'^\d{11}$').hasMatch(ruc) ? null : 'El RUC tiene 11 dígitos';
  }

  String? _blankToNull(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    final session = context.read<IamStore>().session;
    if (session == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ProfilesStore>().completeClinic(
        session: session,
        name: _name.text,
        ruc: _blankToNull(_ruc.text),
        address: _blankToNull(_address.text),
        phoneNumber: FormValidators.toApiPhone(_phone.text),
      );
    } on ApiError catch (error) {
      if (mounted) {
        setState(
          () => _error = error.isNetworkError
              ? error.message
              : error.isConflict
              ? 'Ya existe una clínica con esos datos.'
              : 'No se pudo guardar la clínica: ${error.message}',
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
                  title: 'Registra tu clínica',
                  subtitle: 'Tus pacientes y consultas quedarán asociados a ella',
                ),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'Nombre de la clínica',
                  hint: 'Obligatorio',
                  child: TextFormField(
                    key: const Key('clinic.name'),
                    controller: _name,
                    validator: (v) => FormValidators.required(v, 'Ingresa el nombre de la clínica'),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Clínica VetSur',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'RUC',
                  hint: 'Opcional',
                  child: TextFormField(
                    controller: _ruc,
                    validator: _validateRuc,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Dirección',
                  hint: 'Opcional',
                  child: TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      hintText: 'Av. José Pardo 840, Miraflores',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Teléfono',
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
                if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
                const SizedBox(height: 24),
                PrimaryButton(
                  key: const Key('clinic.submit'),
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
