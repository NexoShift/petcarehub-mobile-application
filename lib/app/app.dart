import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../shared/presentation/theme/app_theme.dart';

/// Widget raíz: tema + router. Los stores se inyectan arriba (ver main.dart).
class PetCareHubApp extends StatelessWidget {
  const PetCareHubApp({super.key, required this.router, this.useGoogleFonts = true});

  final GoRouter router;
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PetCare Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
      routerConfig: router,
    );
  }
}
