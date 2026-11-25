import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../application/pets_store.dart';
import '../../../application/profiles_store.dart';
import '../../widgets/pet_list_tile.dart';

/// Pestaña "Mis mascotas" del dueño.
class PetListView extends StatefulWidget {
  const PetListView({super.key});

  @override
  State<PetListView> createState() => _PetListViewState();
}

class _PetListViewState extends State<PetListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final ownerId = context.read<ProfilesStore>().petOwner?.id;
    if (ownerId != null) await context.read<PetsStore>().load(ownerId, force: force);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PetsStore>();
    final pets = store.pets;

    Widget body;
    if (store.status == LoadStatus.error) {
      body = EmptyState(
        icon: Icons.wifi_off,
        title: 'No se pudieron cargar tus mascotas',
        message: store.error,
        actionLabel: 'Reintentar',
        onAction: () => _load(force: true),
      );
    } else if (store.status != LoadStatus.loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (pets.isEmpty) {
      body = EmptyState(
        icon: Icons.pets,
        title: 'Aún no registras mascotas',
        message: 'Registra a tu mascota para tener su historia clínica en un solo lugar.',
        actionLabel: 'Registrar mascota',
        onAction: () => context.push(AppRoutes.newPet),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: pets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => PetListTile(
            pet: pets[i],
            onTap: () => context.push(AppRoutes.pet(pets[i].id)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis mascotas', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: body,
      floatingActionButton: pets.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.turquoise,
              foregroundColor: AppColors.navy,
              onPressed: () => context.push(AppRoutes.newPet),
              icon: const Icon(Icons.add),
              label: const Text('Nueva mascota'),
            ),
    );
  }
}
