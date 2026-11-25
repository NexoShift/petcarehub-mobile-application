import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../../shared/domain/api_error.dart';
import '../../../../shared/domain/picked_image.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/validators.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/error_banner.dart';
import '../../../../shared/presentation/widgets/labeled_field.dart';
import '../../../../shared/presentation/widgets/photo_picker_field.dart';
import '../../../../shared/presentation/widgets/primary_button.dart';
import '../../../../shared/presentation/widgets/profile_avatar.dart';
import '../../../../shared/presentation/widgets/section_header.dart';
import '../../application/profiles_store.dart';
import '../../domain/model/person_sex.dart';
import '../../domain/model/pet_owner.dart';

/// Pestaña "Perfil". El dueño edita sus datos y su foto; el veterinario y el
/// admin ven su ficha y su clínica (se editan desde la web).
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfilesStore>();
    final owner = profiles.petOwner;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (owner != null)
            _OwnerProfileForm(key: ValueKey(owner.id), owner: owner)
          else
            const _ClinicProfileCard(),
          const SizedBox(height: 24),
          const _AccountSection(),
        ],
      ),
    );
  }
}

class _OwnerProfileForm extends StatefulWidget {
  const _OwnerProfileForm({super.key, required this.owner});

  final PetOwner owner;

  @override
  State<_OwnerProfileForm> createState() => _OwnerProfileFormState();
}

class _OwnerProfileFormState extends State<_OwnerProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.owner.firstName);
  late final _lastName = TextEditingController(text: widget.owner.lastName);
  late final _phone = TextEditingController(
    text: FormValidators.fromApiPhone(widget.owner.phoneNumber),
  );
  late PersonSex? _sex = widget.owner.sex;
  PickedImage? _preview;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _uploadPhoto(PickedImage image) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _preview = image;
      _uploading = true;
    });
    try {
      await context.read<ProfilesStore>().updatePetOwnerImage(image);
      messenger.showSnackBar(const SnackBar(content: Text('Foto actualizada')));
    } on ApiError catch (error) {
      setState(() => _preview = null);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo subir la foto: ${error.message}')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ProfilesStore>().updatePetOwner(
            firstName: _firstName.text,
            lastName: _lastName.text,
            phoneNumber: FormValidators.toApiPhone(_phone.text),
            sex: _sex,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Datos guardados')));
    } on ApiError catch (error) {
      if (mounted) setState(() => _error = 'No se pudieron guardar los cambios: ${error.message}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<ProfilesStore>().petOwner ?? widget.owner;
    final text = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              PhotoPickerField(
                imageUrl: owner.profileImageUrl,
                preview: _preview,
                initials: ProfileAvatar.initialsOf(owner.firstName, owner.lastName),
                fallbackIcon: Icons.person,
                onPicked: _uploadPhoto,
              ),
              if (_uploading) const CircularProgressIndicator(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            owner.fullName,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          Text(
            owner.email,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Datos personales'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: 'Nombres',
                  child: TextFormField(
                    key: const Key('profile.firstName'),
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => FormValidators.required(v, 'Ingresa tus nombres'),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Apellidos',
                  child: TextFormField(
                    key: const Key('profile.lastName'),
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => FormValidators.required(v, 'Ingresa tus apellidos'),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Teléfono móvil',
                  hint: 'Opcional',
                  child: TextFormField(
                    key: const Key('profile.phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    validator: FormValidators.optionalPeruvianMobile,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(prefixText: '+51 '),
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
                      for (final s in PersonSex.values) ButtonSegment(value: s, label: Text(s.label)),
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
                const SizedBox(height: 16),
                PrimaryButton(
                  key: const Key('profile.save'),
                  label: 'Guardar cambios',
                  showArrow: false,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ficha del veterinario y de su clínica (solo lectura en el móvil).
class _ClinicProfileCard extends StatelessWidget {
  const _ClinicProfileCard();

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfilesStore>();
    final session = context.watch<IamStore>().session;
    final vet = profiles.veterinarian;
    final clinic = profiles.clinic;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: AppColors.textMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ProfileAvatar(
            radius: 48,
            imageUrl: vet?.profileImageUrl ?? clinic?.profileImageUrl,
            initials: vet == null ? null : ProfileAvatar.initialsOf(vet.firstName, vet.lastName),
            fallbackIcon: Icons.local_hospital,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          vet != null ? 'Dr(a). ${vet.fullName}' : clinic?.name ?? '',
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        Text(session?.email ?? '', textAlign: TextAlign.center, style: muted),
        if (vet?.licenseNumber != null) ...[
          const SizedBox(height: 4),
          Text(
            'CMVP ${vet!.licenseNumber}${vet.specialty == null ? '' : ' • ${vet.specialty}'}',
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(color: AppColors.deepBlue),
          ),
        ],
        const SizedBox(height: 24),
        const SectionHeader(title: 'Centro veterinario'),
        const SizedBox(height: 8),
        AppCard(
          child: clinic == null
              ? Text(
                  'Tu perfil de veterinario aún no está registrado. Pide al administrador de tu clínica que lo complete desde la web.',
                  style: muted,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    if (clinic.address != null) Text(clinic.address!, style: muted),
                    if (clinic.phoneNumber != null) Text(clinic.phoneNumber!, style: muted),
                    if (clinic.ruc != null) Text('RUC ${clinic.ruc}', style: muted),
                    const SizedBox(height: 8),
                    Text(
                      'Los datos de la clínica y del equipo se editan desde la web.',
                      style: muted?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Cuenta'),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.navy),
                title: const Text('Cambiar contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.changePassword),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.danger)),
                onTap: () => context.read<IamStore>().signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
