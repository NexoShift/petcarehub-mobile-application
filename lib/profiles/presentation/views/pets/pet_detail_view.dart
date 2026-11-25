import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_routes.dart';
import '../../../../clinical_attention/presentation/widgets/pet_consultations_section.dart';
import '../../../../shared/domain/api_error.dart';
import '../../../../shared/presentation/formatters.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/info_tile.dart';
import '../../../../shared/presentation/widgets/section_header.dart';
import '../../../../shared/presentation/widgets/status_chip.dart';
import '../../../application/pets_store.dart';
import '../../../domain/model/clinic.dart';
import '../../../domain/model/pet.dart';
import '../../../domain/model/pet_sex.dart';
import '../../widgets/pet_code_chip.dart';
import '../../widgets/pet_photo.dart';

/// MM-05 Perfil de mascota y ficha biológica. La usan el dueño ([canEdit] true)
/// y el veterinario (solo lectura, desde la lista de pacientes).
class PetDetailView extends StatefulWidget {
  const PetDetailView({super.key, required this.petId, this.canEdit = false});

  final int petId;
  final bool canEdit;

  @override
  State<PetDetailView> createState() => _PetDetailViewState();
}

class _PetDetailViewState extends State<PetDetailView> {
  late Future<PetDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = context.read<PetsStore>().fetchDetail(widget.petId);
  }

  void _reload() => setState(() => _detail = context.read<PetsStore>().fetchDetail(widget.petId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PetDetail>(
      future: _detail,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Perfil de mascota'),
            actions: [
              if (widget.canEdit && detail != null)
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await context.push(AppRoutes.editPet(widget.petId));
                    if (mounted) _reload();
                  },
                ),
            ],
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true, :final error) => EmptyState(
                icon: Icons.error_outline,
                title: 'No se pudo cargar la mascota',
                message: error is ApiError ? error.message : null,
                actionLabel: 'Reintentar',
                onAction: _reload,
              ),
            _ when detail == null => const Center(child: CircularProgressIndicator()),
            _ => RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _Header(pet: detail.pet),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BiologicalRecord(pet: detail.pet),
                          const SizedBox(height: 24),
                          _Clinics(clinics: detail.clinics, isOwner: widget.canEdit),
                          const SizedBox(height: 24),
                          PetConsultationsSection(petId: widget.petId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.turquoiseSoft, AppColors.background],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipOval(child: PetPhoto(pet: pet, size: 112, radius: 56)),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                pet.name,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              StatusChip(
                label: pet.species.label,
                color: AppColors.deepBlue,
                icon: PetPhoto.iconFor(pet.species),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PetCodeChip(petCode: pet.petCode),
        ],
      ),
    );
  }
}

class _BiologicalRecord extends StatelessWidget {
  const _BiologicalRecord({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      InfoTile(label: 'Especie', value: pet.species.label, icon: PetPhoto.iconFor(pet.species)),
      InfoTile(
        label: 'Raza',
        value: pet.breed?.isNotEmpty == true ? pet.breed! : 'Sin registrar',
        icon: Icons.category_outlined,
      ),
      InfoTile(
        label: 'Sexo biológico',
        value: pet.sex?.label ?? 'Sin registrar',
        icon: pet.sex == PetSex.female ? Icons.female : Icons.male,
      ),
      InfoTile(
        label: 'Edad',
        value: pet.birthDate == null ? 'Sin registrar' : Formatters.age(pet.birthDate!),
        icon: Icons.cake_outlined,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Ficha biológica'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final t in tiles) SizedBox(width: width, child: t)],
            );
          },
        ),
      ],
    );
  }
}

class _Clinics extends StatelessWidget {
  const _Clinics({required this.clinics, required this.isOwner});

  final List<Clinic> clinics;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Centros veterinarios'),
        const SizedBox(height: 8),
        if (clinics.isEmpty)
          AppCard(
            color: AppColors.turquoiseSoft,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.deepBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOwner
                        ? 'Aún no está registrada en ninguna clínica. Comparte su ID con tu veterinario para que la registre como paciente.'
                        : 'No está registrada en ninguna clínica.',
                    style: text.bodySmall?.copyWith(color: AppColors.navy),
                  ),
                ),
              ],
            ),
          )
        else
          for (final clinic in clinics) ...[
            AppCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.navy,
                    child: Icon(Icons.local_hospital, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinic.name,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        if (clinic.address != null && clinic.address!.isNotEmpty)
                          Text(
                            clinic.address!,
                            style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                          ),
                        if (clinic.phoneNumber != null && clinic.phoneNumber!.isNotEmpty)
                          Text(
                            clinic.phoneNumber!,
                            style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
