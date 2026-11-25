import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../shared/domain/api_error.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/error_banner.dart';
import '../../../shared/presentation/widgets/primary_button.dart';
import '../../application/clinic_patients_store.dart';
import '../../domain/model/pet.dart';
import 'pet_list_tile.dart';

/// "+ Registrar paciente" (MM-13): el vet escribe el código que le da el dueño
/// (PET-XXXXXXXX), ve la mascota y confirma.
Future<void> showRegisterPatientSheet(BuildContext context, {required int clinicId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider<ClinicPatientsStore>.value(
      value: context.read<ClinicPatientsStore>(),
      child: _RegisterPatientSheet(clinicId: clinicId),
    ),
  );
}

class _RegisterPatientSheet extends StatefulWidget {
  const _RegisterPatientSheet({required this.clinicId});

  final int clinicId;

  @override
  State<_RegisterPatientSheet> createState() => _RegisterPatientSheetState();
}

class _RegisterPatientSheetState extends State<_RegisterPatientSheet> {
  static final _codePattern = RegExp(r'^PET-[A-HJ-NP-Z2-9]{8}$');

  final _code = TextEditingController(text: 'PET-');
  Pet? _found;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _code.text.trim().toUpperCase();
    if (!_codePattern.hasMatch(code)) {
      setState(() => _error = 'El código tiene el formato PET- y 8 caracteres.');
      return;
    }
    await _run(() async {
      final pet = await context.read<ClinicPatientsStore>().findByCode(code);
      setState(() {
        _found = pet;
        _error = pet == null ? 'No existe una mascota con ese código.' : null;
      });
    });
  }

  Future<void> _register() async {
    final pet = _found;
    if (pet == null) return;
    final store = context.read<ClinicPatientsStore>();
    if (store.isPatient(pet.id)) {
      setState(() => _error = '${pet.name} ya es paciente de tu clínica.');
      return;
    }
    await _run(() async {
      await store.register(clinicId: widget.clinicId, pet: pet);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pet.name} ahora es paciente de tu clínica')),
      );
      Navigator.pop(context);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on ApiError catch (error) {
      if (mounted) {
        setState(() => _error = error.isConflict
            ? 'Esta mascota ya es paciente de tu clínica.'
            : error.message);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registrar paciente',
            style: text.titleLarge?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Pide al tutor el ID de su mascota. Lo encuentra en el perfil de la mascota en su app.',
            style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('patient.code'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {
              if (_found != null) setState(() => _found = null);
            },
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: IconButton(
                tooltip: 'Buscar',
                icon: const Icon(Icons.search),
                onPressed: _loading ? null : _search,
              ),
            ),
          ),
          if (_found != null) ...[
            const SizedBox(height: 16),
            PetListTile(pet: _found!, trailing: const SizedBox.shrink()),
          ],
          if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(_error!)],
          const SizedBox(height: 16),
          PrimaryButton(
            key: const Key('patient.submit'),
            label: _found == null ? 'Buscar mascota' : 'Registrar como paciente',
            showArrow: false,
            loading: _loading,
            onPressed: _found == null ? _search : _register,
          ),
        ],
      ),
    );
  }
}
