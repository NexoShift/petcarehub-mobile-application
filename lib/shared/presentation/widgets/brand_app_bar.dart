import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Barra superior de MM-02/MM-03: flecha atrás, logo y "PetCare Hub".
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: onBack == null
          ? null
          : IconButton(tooltip: 'Volver', icon: const Icon(Icons.arrow_back), onPressed: onBack),
      automaticallyImplyLeading: false,
      titleSpacing: onBack == null ? 16 : 0,
      title: Row(
        children: [
          Image.asset('assets/images/logo-petcarehub.png', height: 28),
          const SizedBox(width: 8),
          Text(
            'PetCare Hub',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}
