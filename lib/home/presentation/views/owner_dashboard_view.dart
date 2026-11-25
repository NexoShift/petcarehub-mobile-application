import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../clinical_attention/application/consultations_store.dart';
import '../../../clinical_attention/presentation/widgets/consultation_tile.dart';
import '../../../profiles/application/pets_store.dart';
import '../../../profiles/application/profiles_store.dart';
import '../../../profiles/domain/model/pet.dart';
import '../../../profiles/presentation/widgets/pet_code_chip.dart';
import '../../../profiles/presentation/widgets/pet_photo.dart';
import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/empty_state.dart';
import '../../../shared/presentation/widgets/profile_avatar.dart';
import '../../../shared/presentation/widgets/section_header.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_action_card.dart';

/// MM-04 Dashboard central del dueño de mascota.
///
/// Reúne datos de dos bounded contexts: Profiles (mascotas) y Clinical
/// Attention (consultas). Cada uno a través de su propio store.
class OwnerDashboardView extends StatefulWidget {
  const OwnerDashboardView({super.key});

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final ownerId = context.read<ProfilesStore>().petOwner?.id;
    if (ownerId == null) return;
    final pets = context.read<PetsStore>();
    await pets.load(ownerId, force: force);
    final selected = pets.selectedPet;
    if (selected != null && mounted) {
      await context.read<ConsultationsStore>().loadForPet(selected.id, force: force);
    }
  }

  void _select(Pet pet) {
    context.read<PetsStore>().select(pet.id);
    context.read<ConsultationsStore>().loadForPet(pet.id);
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<ProfilesStore>().petOwner;
    final petsStore = context.watch<PetsStore>();
    final selected = petsStore.selectedPet;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              DashboardHeader(
                role: 'Dueño de mascota',
                greeting: '¡Hola, ${owner?.firstName ?? ''}!',
                imageUrl: owner?.profileImageUrl,
                initials: owner == null
                    ? null
                    : ProfileAvatar.initialsOf(owner.firstName, owner.lastName),
              ),
              const SizedBox(height: 24),
              ..._petsSection(petsStore),
              if (selected != null) ...[
                const SizedBox(height: 16),
                _SelectedPetCard(pet: selected),
                const SizedBox(height: 24),
                _LastConsultation(pet: selected),
              ],
              const SizedBox(height: 24),
              const SectionHeader(title: 'Herramientas y acciones rápidas'),
              const SizedBox(height: 8),
              _QuickActions(pet: selected),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _petsSection(PetsStore store) {
    if (store.status == LoadStatus.error) {
      return [
        EmptyState(
          icon: Icons.wifi_off,
          title: 'No se pudieron cargar tus mascotas',
          message: store.error,
          actionLabel: 'Reintentar',
          onAction: () => _load(force: true),
        ),
      ];
    }
    if (store.status != LoadStatus.loaded) {
      return [const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))];
    }
    if (store.pets.isEmpty) {
      return [
        AppCard(
          child: EmptyState(
            icon: Icons.pets,
            title: 'Registra a tu primera mascota',
            message: 'Así tendrás su historia clínica siempre a la mano.',
            actionLabel: 'Registrar mascota',
            onAction: () => context.push(AppRoutes.newPet),
          ),
        ),
      ];
    }
    final selectedId = store.selectedPet?.id;
    return [
      SectionHeader(
        title: 'Mis mascotas',
        actionLabel: '${store.pets.length} registrada${store.pets.length == 1 ? '' : 's'}',
        onAction: () => StatefulNavigationShell.of(context).goBranch(1),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: store.pets.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            if (i == store.pets.length) return _AddPetCard(onTap: () => context.push(AppRoutes.newPet));
            final pet = store.pets[i];
            return _PetCard(pet: pet, selected: pet.id == selectedId, onTap: () => _select(pet));
          },
        ),
      ),
    ];
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.selected, required this.onTap});

  final Pet pet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: pet.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 116,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.turquoise : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  ClipOval(child: PetPhoto(pet: pet, size: 56, radius: 28)),
                  const SizedBox(height: 8),
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  Text(
                    [
                      pet.species.label,
                      if (pet.birthDate != null) Formatters.age(pet.birthDate!),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              if (selected)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.check_circle, color: AppColors.turquoise, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  const _AddPetCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.turquoiseSoft,
              child: Icon(Icons.add, color: AppColors.turquoise),
            ),
            SizedBox(height: 8),
            Text('Nueva', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Resumen de la mascota elegida: código y cifras de sus consultas.
class _SelectedPetCard extends StatelessWidget {
  const _SelectedPetCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final consultations = context.watch<ConsultationsStore>().consultationsOf(pet.id);
    final last = consultations?.firstOrNull;

    return AppCard(
      onTap: () => context.push(AppRoutes.pet(pet.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PetPhoto(pet: pet, size: 48, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    Text(
                      pet.speciesAndBreed,
                      style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          PetCodeChip(petCode: pet.petCode),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(label: 'Atenciones', value: consultations == null ? '–' : '${consultations.length}'),
              _Stat(label: 'Última visita', value: last == null ? '–' : Formatters.date(last.date)),
              _Stat(
                label: 'Edad',
                value: pet.birthDate == null ? '–' : Formatters.age(pet.birthDate!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastConsultation extends StatelessWidget {
  const _LastConsultation({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ConsultationsStore>();
    final consultations = store.consultationsOf(pet.id);
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted);

    Widget body;
    if (store.errorOf(pet.id) != null) {
      body = Text('No se pudo cargar la última atención.', style: muted);
    } else if (consultations == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (consultations.isEmpty) {
      body = AppCard(child: Text('${pet.name} aún no tiene consultas registradas.', style: muted));
    } else {
      final last = consultations.first;
      body = ConsultationTile(
        consultation: last,
        onTap: () => context.push(AppRoutes.petConsultation(pet.id, last.id)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Última atención',
          actionLabel: consultations?.isNotEmpty == true ? 'Ver historial' : null,
          onAction: () => context.push(AppRoutes.petHistory(pet.id)),
        ),
        const SizedBox(height: 8),
        body,
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.pet});

  final Pet? pet;

  @override
  Widget build(BuildContext context) {
    final actions = [
      QuickActionCard(
        icon: Icons.folder_shared_outlined,
        title: 'Historia clínica',
        subtitle: 'Línea de tiempo',
        onTap: pet == null ? null : () => context.push(AppRoutes.petHistory(pet!.id)),
      ),
      const QuickActionCard(
        icon: Icons.medication_outlined,
        title: 'Tratamientos',
        subtitle: 'Recetas activas',
      ),
      const QuickActionCard(
        icon: Icons.auto_awesome,
        title: 'Explicar con IA',
        subtitle: 'Aclarar diagnósticos',
        highlighted: true,
      ),
      const QuickActionCard(
        icon: Icons.center_focus_strong_outlined,
        title: 'Análisis visual',
        subtitle: 'Triaje orientativo',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final a in actions) SizedBox(width: width, child: a)],
        );
      },
    );
  }
}
