import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../iam/application/iam_store.dart';
import '../../../shared/presentation/theme/app_colors.dart';

/// Barra inferior. El dueño ve Inicio, Mascotas y Perfil; el veterinario ve
/// Pacientes, Consultas y Perfil. Cada pestaña es una rama de StatefulShellRoute, así que
/// conserva su scroll y su estado al cambiar de pestaña.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Índices de rama de go_router: 0 inicio, 1 mascotas, 2 perfil, 3 consultas.
  static const _ownerBranches = [0, 1, 2];
  static const _vetBranches = [0, 3, 2];
  static const _clinicBranches = [0, 2];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<IamStore>().session;
    final isOwner = session?.isPetOwner ?? false;
    final isVet = session?.isVeterinarian ?? false;
    final branches = isOwner
        ? _ownerBranches
        : isVet
        ? _vetBranches
        : _clinicBranches;
    final selected = branches.indexOf(navigationShell.currentIndex).clamp(0, branches.length - 1);

    final destinations = isOwner
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Mis mascotas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ]
        : [
            const NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Pacientes',
            ),
            if (isVet)
              const NavigationDestination(
                icon: Icon(Icons.medical_services_outlined),
                selectedIcon: Icon(Icons.medical_services),
                label: 'Consultas',
              ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.turquoiseSoft,
        selectedIndex: selected,
        destinations: destinations,
        onDestinationSelected: (index) {
          final branch = branches[index];
          // Tocar la pestaña activa vuelve a su pantalla inicial.
          navigationShell.goBranch(branch, initialLocation: branch == navigationShell.currentIndex);
        },
      ),
    );
  }
}
