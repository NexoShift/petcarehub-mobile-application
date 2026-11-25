import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../shared/domain/api_error.dart';
import '../../../../shared/domain/picked_image.dart';
import '../../../../shared/presentation/formatters.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/validators.dart';
import '../../../../shared/presentation/widgets/error_banner.dart';
import '../../../../shared/presentation/widgets/labeled_field.dart';
import '../../../../shared/presentation/widgets/photo_picker_field.dart';
import '../../../../shared/presentation/widgets/primary_button.dart';
import '../../../application/pets_store.dart';
import '../../../application/profiles_store.dart';
import '../../../domain/model/pet.dart';
import '../../../domain/model/pet_draft.dart';
import '../../../domain/model/pet_sex.dart';
import '../../../domain/model/species.dart';

/// Registrar (sin [petId]) o editar (con [petId]) una mascota.
class PetFormView extends StatefulWidget {
  const PetFormView({super.key, this.petId});

  final int? petId;

  @override
  State<PetFormView> createState() => _PetFormViewState();
}

class _PetFormViewState extends State<PetFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  Species _species = Species.dog;
  PetSex? _sex;
  DateTime? _birthDate;
  PickedImage? _image;
  Pet? _editing;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.petId != null;

  @override
  void initState() {
    super.initState();
    _editing = _isEdit ? context.read<PetsStore>().byId(widget.petId!) : null;
    _name = TextEditingController(text: _editing?.name);
    _breed = TextEditingController(text: _editing?.breed);
    _species = _editing?.species ?? Species.dog;
    _sex = _editing?.sex;
    _birthDate = _editing?.birthDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 40),
      // El backend rechaza fechas futuras.
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    final store = context.read<PetsStore>();
    final ownerId = context.read<ProfilesStore>().petOwner?.id;
    if (ownerId == null) return;

    final breed = _breed.text.trim();
    final draft = PetDraft(
      name: _name.text.trim(),
      species: _species,
      breed: breed.isEmpty ? null : breed,
      birthDate: _birthDate,
      sex: _sex,
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await store.update(petId: widget.petId!, draft: draft, image: _image);
        if (mounted) context.pop();
      } else {
        final pet = await store.create(ownerId: ownerId, draft: draft, image: _image);
        if (mounted) context.pushReplacement(AppRoutes.pet(pet.id));
      }
    } on ApiError catch (error) {
      if (mounted) {
        setState(() => _error = error.isNetworkError
            ? error.message
            : 'No se pudo guardar la mascota: ${error.message}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar mascota' : 'Nueva mascota')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhotoPickerField(
                  imageUrl: _editing?.profileImageUrl,
                  preview: _image,
                  onPicked: (image) => setState(() => _image = image),
                ),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'Nombre',
                  hint: 'Obligatorio',
                  child: TextFormField(
                    key: const Key('pet.name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => FormValidators.required(v, 'Ingresa el nombre'),
                    decoration: const InputDecoration(hintText: 'Max'),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Especie',
                  child: SegmentedButton<Species>(
                    showSelectedIcon: false,
                    segments: [
                      for (final s in Species.values) ButtonSegment(value: s, label: Text(s.label)),
                    ],
                    selected: {_species},
                    onSelectionChanged: (s) => setState(() => _species = s.first),
                    style: _segmentStyle,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Raza',
                  hint: 'Opcional',
                  child: TextFormField(
                    key: const Key('pet.breed'),
                    controller: _breed,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Golden Retriever'),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Fecha de nacimiento',
                  hint: 'Opcional',
                  child: InkWell(
                    key: const Key('pet.birthDate'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickBirthDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: _birthDate == null
                            ? null
                            : IconButton(
                                tooltip: 'Quitar fecha',
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _birthDate = null),
                              ),
                      ),
                      child: Text(
                        _birthDate == null
                            ? 'Elegir fecha'
                            : '${Formatters.date(_birthDate!)} (${Formatters.age(_birthDate!)})',
                        style: TextStyle(
                          color: _birthDate == null ? AppColors.textMuted : AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Sexo',
                  hint: 'Opcional',
                  child: SegmentedButton<PetSex>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: [
                      for (final s in PetSex.values) ButtonSegment(value: s, label: Text(s.label)),
                    ],
                    selected: {?_sex},
                    onSelectionChanged: (s) => setState(() => _sex = s.isEmpty ? null : s.first),
                    style: _segmentStyle,
                  ),
                ),
                if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(_error!)],
                const SizedBox(height: 24),
                PrimaryButton(
                  key: const Key('pet.submit'),
                  label: _isEdit ? 'Guardar cambios' : 'Registrar mascota',
                  showArrow: false,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final _segmentStyle = SegmentedButton.styleFrom(
    selectedBackgroundColor: AppColors.turquoiseSoft,
    selectedForegroundColor: AppColors.navy,
  );
}
