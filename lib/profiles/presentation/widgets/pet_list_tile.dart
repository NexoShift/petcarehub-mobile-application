import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/formatters.dart';
import '../../../shared/presentation/theme/app_colors.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../domain/model/pet.dart';
import '../../domain/model/pet_sex.dart';
import 'pet_code_chip.dart';
import 'pet_photo.dart';

/// Fila de mascota/paciente: foto, nombre, sexo, especie y raza, edad y código.
class PetListTile extends StatelessWidget {
  const PetListTile({super.key, required this.pet, this.onTap, this.trailing});

  final Pet pet;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final details = [
      pet.speciesAndBreed,
      if (pet.birthDate != null) Formatters.age(pet.birthDate!),
    ].join(' • ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PetPhoto(pet: pet, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pet.name,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (pet.sex != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        pet.sex == PetSex.male ? Icons.male : Icons.female,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                PetCodeChip(petCode: pet.petCode, copyable: false),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
