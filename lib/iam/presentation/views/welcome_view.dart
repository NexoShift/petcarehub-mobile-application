import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/theme/app_colors.dart';

/// MM-01 Splash Screen & Bienvenida.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset('assets/images/logo-petcarehub.png', height: 64),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PetCare Hub',
                    style: text.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Historias clínicas interoperables y\nasistencia inteligente',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  const _HeroCard(),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.signUp),
                    child: const Text('Comenzar'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta?',
                        style: text.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: () => context.go(AppRoutes.signIn),
                        child: const Text(
                          'Iniciar Sesión',
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta blanca con la ilustración y el mensaje principal.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              // Exporta la ilustración del Figma a assets/images/welcome.png.
              // Mientras no exista se muestra un fondo con el ícono de la marca.
              child: Image.asset(
                'assets/images/welcome.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.turquoiseSoft,
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, size: 72, color: AppColors.turquoise),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mantén la historia clínica completa de tu mascota siempre accesible en cualquier veterinaria',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_dot(active: true), _dot(), _dot()],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _dot({bool active = false}) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 3),
    width: active ? 18 : 6,
    height: 6,
    decoration: BoxDecoration(
      color: active ? AppColors.turquoise : AppColors.border,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
