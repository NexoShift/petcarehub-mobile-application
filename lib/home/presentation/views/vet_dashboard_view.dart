import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../iam/application/iam_store.dart';
import '../../../profiles/application/clinic_patients_store.dart';
import '../../../profiles/application/pets_store.dart' show LoadStatus;
import '../../../profiles/application/profiles_store.dart';
import '../../../profiles/domain/model/species.dart';
import '../../../profiles/presentation/widgets/pet_list_tile.dart';
import '../../../profiles/presentation/widgets/register_patient_sheet.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';
import '../widgets/dashboard_header.dart';

/// MM-13 Directorio de pacientes de la clínica (inicio del veterinario).
class VetDashboardView extends StatefulWidget {
  const VetDashboardView({super.key});

  @override
  State<VetDashboardView> createState() => _VetDashboardViewState();
}

class _VetDashboardViewState extends State<VetDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final clinicId = context.read<ProfilesStore>().clinicId;
    if (clinicId != null) await context.read<ClinicPatientsStore>().load(clinicId, force: force);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfilesStore>();
    final store = context.watch<ClinicPatientsStore>();
    final session = context.watch<IamStore>().session;
    final vet = profiles.veterinarian;
    final clinicId = profiles.clinicId;
    final text = Theme.of(context).textTheme;

    final header = Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(
            dark: true,
            role: profiles.clinic?.name ?? 'Médico veterinario',
            greeting: vet != null
                ? 'Dr(a). ${vet.firstName}'
                : (session?.isClinicAdmin ?? false)
                    ? 'Administración'
                    : 'Pacientes clínicos',
            imageUrl: vet?.profileImageUrl,
            initials: vet == null ? null : ProfileAvatar.initialsOf(vet.firstName, vet.lastName),
          ),
          if (clinicId != null) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('patients.search'),
              onChanged: store.search,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                fillColor: Colors.white,
                hintText: 'Buscar por mascota, raza o ID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ],
        ],
      ),
    );

    Widget body;
    if (clinicId == null) {
      body = const EmptyState(
        icon: Icons.badge_outlined,
        title: 'Tu perfil aún no está listo',
        message:
            'El administrador de tu clínica debe registrar tu perfil de veterinario desde la web.',
      );
    } else if (store.status == LoadStatus.error) {
      body = EmptyState(
        icon: Icons.wifi_off,
        title: 'No se pudieron cargar los pacientes',
        message: store.error,
        actionLabel: 'Reintentar',
        onAction: () => _load(force: true),
      );
    } else if (store.status != LoadStatus.loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final patients = store.patients;
      body = RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filter(store, null, 'Todos (${store.allPatients.length})'),
                  for (final s in Species.values) _filter(store, s, '${s.label}s (${store.countOf(s)})'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (store.allPatients.isEmpty)
              const EmptyState(
                icon: Icons.groups_outlined,
                title: 'Aún no tienes pacientes',
                message: 'Registra uno con el ID que te da el tutor de la mascota.',
              )
            else if (patients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ningún paciente coincide con la búsqueda.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              )
            else
              for (final pet in patients) ...[
                PetListTile(pet: pet, onTap: () => context.push(AppRoutes.patient(pet.id))),
                const SizedBox(height: 12),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [header, Expanded(child: body)]),
      ),
      floatingActionButton: clinicId == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('patients.register'),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              onPressed: () => showRegisterPatientSheet(context, clinicId: clinicId),
              icon: const Icon(Icons.add),
              label: const Text('Registrar paciente'),
            ),
    );
  }

  Widget _filter(ClinicPatientsStore store, Species? species, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: store.speciesFilter == species,
        onSelected: (_) => store.filterBySpecies(species),
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(
          color: store.speciesFilter == species ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
      ),
    );
  }
}
