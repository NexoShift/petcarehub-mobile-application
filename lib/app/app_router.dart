import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../home/presentation/views/home_shell.dart';
import '../home/presentation/views/home_view.dart';
import '../iam/application/iam_store.dart';
import '../iam/presentation/views/change_password_view.dart';
import '../iam/presentation/views/sign_in_view.dart';
import '../iam/presentation/views/sign_up_view.dart';
import '../iam/presentation/views/welcome_view.dart';
import '../profiles/application/profiles_store.dart';
import '../profiles/presentation/views/complete_clinic_profile_view.dart';
import '../profiles/presentation/views/complete_pet_owner_profile_view.dart';
import '../profiles/presentation/views/my_profile_view.dart';
import '../profiles/presentation/views/pets/pet_detail_view.dart';
import '../profiles/presentation/views/pets/pet_form_view.dart';
import '../profiles/presentation/views/pets/pet_list_view.dart';
import 'app_routes.dart';
import 'boot_view.dart';

/// Rutas y guards de la app. Es el equivalente a app.routes.ts + authGuard +
/// profileCompletedGuard + roleGuard del front Angular, en una sola función [redirect].
GoRouter createRouter({required IamStore iam, required ProfilesStore profiles}) {
  // Navegador raíz: las pantallas completas (detalle, formularios) se abren
  // encima de la barra inferior.
  final rootKey = GlobalKey<NavigatorState>();

  int petIdOf(GoRouterState state) => int.parse(state.pathParameters['petId']!);

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.boot,
    refreshListenable: Listenable.merge([iam, profiles]),
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      iam: iam,
      profiles: profiles,
    ),
    routes: [
      GoRoute(path: AppRoutes.boot, builder: (_, _) => const BootView()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeView()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInView()),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpView()),
      GoRoute(path: AppRoutes.changePassword, builder: (_, _) => const ChangePasswordView()),
      GoRoute(
        path: AppRoutes.completePetOwner,
        builder: (_, _) => const CompletePetOwnerProfileView(),
      ),
      GoRoute(
        path: AppRoutes.completeClinic,
        builder: (_, _) => const CompleteClinicProfileView(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeView())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pets,
                builder: (_, _) => const PetListView(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const PetFormView(),
                  ),
                  GoRoute(
                    path: ':petId',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => PetDetailView(petId: petIdOf(state), canEdit: true),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootKey,
                        builder: (_, state) => PetFormView(petId: petIdOf(state)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const MyProfileView())],
          ),
        ],
      ),
      GoRoute(
        path: '/patients/:petId',
        builder: (_, state) => PetDetailView(petId: petIdOf(state)),
      ),
    ],
  );
}

/// Decide a dónde debe ir el usuario. Devuelve null si puede quedarse.
/// Es una función pura para poder probarla sin widgets.
@visibleForTesting
String? resolveRedirect({
  required String location,
  required IamStore iam,
  required ProfilesStore profiles,
}) {
  // 1. Aún no sabemos si hay sesión: pantalla de carga.
  if (iam.status == AuthStatus.unknown) {
    return location == AppRoutes.boot ? null : AppRoutes.boot;
  }

  // 2. Sin sesión: solo bienvenida, login y registro.
  if (iam.status == AuthStatus.unauthenticated) {
    return AppRoutes.public.contains(location) ? null : AppRoutes.welcome;
  }

  // 3. Contraseña temporal (vet creado por la clínica): primero debe cambiarla.
  final session = iam.session!;
  if (session.mustChangePassword) {
    return location == AppRoutes.changePassword ? null : AppRoutes.changePassword;
  }

  // 4. Con sesión pero sin saber si tiene perfil: pantalla de carga.
  switch (profiles.status) {
    case ProfileStatus.unknown:
      return location == AppRoutes.boot ? null : AppRoutes.boot;
    case ProfileStatus.missing:
      final target = session.isPetOwner ? AppRoutes.completePetOwner : AppRoutes.completeClinic;
      return location == target ? null : target;
    case ProfileStatus.complete:
      final blocked = location == AppRoutes.boot ||
          AppRoutes.public.contains(location) ||
          AppRoutes.onboarding.contains(location);
      if (blocked) return AppRoutes.home;
      // 5. Guard por rol: mascotas propias solo el dueño; pacientes solo la clínica.
      if (location.startsWith(AppRoutes.pets) && !session.isPetOwner) return AppRoutes.home;
      if (location.startsWith('/patients') && session.isPetOwner) return AppRoutes.home;
      return null;
  }
}
