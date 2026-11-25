import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../iam/application/iam_store.dart';
import '../../../profiles/application/profiles_store.dart';
import '../../../shared/presentation/theme/app_colors.dart';

/// Inicio provisional después del login. Aquí irán MM-04 (dueño) y MM-13 (vet).
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<IamStore>().session;
    final name = context.watch<ProfilesStore>().displayName;
    final text = Theme.of(context).textTheme;
    final role = switch (session) {
      null => '',
      final s when s.isPetOwner => 'Dueño de mascota',
      final s when s.isClinicAdmin => 'Administrador de clínica',
      _ => 'Médico veterinario',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
            Text(
              name.isEmpty ? '¡Hola!' : '¡Hola, $name!',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<IamStore>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets, size: 56, color: AppColors.turquoise),
              const SizedBox(height: 16),
              Text(
                'Sesión iniciada',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                session?.email ?? '',
                style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
