import 'package:material_ui/material_ui.dart';

import '../../../shared/presentation/theme/app_colors.dart';
import '../../domain/model/pet.dart';
import '../../domain/model/species.dart';

/// Foto de la mascota (redondeada) con ícono de respaldo según la especie.
class PetPhoto extends StatelessWidget {
  const PetPhoto({super.key, required this.pet, this.size = 56, this.radius = 16});

  final Pet pet;
  final double size;
  final double radius;

  static IconData iconFor(Species species) => switch (species) {
        Species.dog => Icons.pets,
        Species.cat => Icons.pets_outlined,
        Species.other => Icons.cruelty_free_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.turquoiseSoft,
      alignment: Alignment.center,
      child: Icon(iconFor(pet.species), color: AppColors.turquoise, size: size * 0.45),
    );
    final url = pet.profileImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: url == null || url.isEmpty
            ? fallback
            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
      ),
    );
  }
}
