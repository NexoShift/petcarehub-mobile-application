import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../home/presentation/views/home_view.dart';
import '../iam/application/iam_store.dart';
import '../iam/presentation/views/sign_in_view.dart';
import '../iam/presentation/views/sign_up_view.dart';
import '../iam/presentation/views/welcome_view.dart';
import '../profiles/application/profiles_store.dart';
import '../profiles/presentation/views/complete_clinic_profile_view.dart';
import '../profiles/presentation/views/complete_pet_owner_profile_view.dart';
import 'app_routes.dart';
import 'boot_view.dart';

/// Rutas y guards de la app. Es el equivalente a app.routes.ts + authGuard +
/// profileCompletedGuard del front Angular, pero en una sola función [redirect].
GoRouter createRouter({required IamStore iam, required ProfilesStore profiles}) {
  return GoRouter(
    initialLocation: AppRoutes.boot,
    refreshListenable: Listenable.merge([iam, profiles]),
    redirect: (context, state) =>
        resolveRedirect(location: state.matchedLocation, iam: iam, profiles: profiles),
    routes: [
      GoRoute(path: AppRoutes.boot, builder: (_, _) => const BootView()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeView()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInView()),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpView()),
      GoRoute(
        path: AppRoutes.completePetOwner,
        builder: (_, _) => const CompletePetOwnerProfileView(),
      ),
      GoRoute(path: AppRoutes.completeClinic, builder: (_, _) => const CompleteClinicProfileView()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeView()),
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

  // 3. Con sesión pero sin saber si tiene perfil: pantalla de carga.
  final session = iam.session!;
  switch (profiles.status) {
    case ProfileStatus.unknown:
      return location == AppRoutes.boot ? null : AppRoutes.boot;
    case ProfileStatus.missing:
      final target = session.isPetOwner ? AppRoutes.completePetOwner : AppRoutes.completeClinic;
      return location == target ? null : target;
    case ProfileStatus.complete:
      final blocked =
          location == AppRoutes.boot ||
          AppRoutes.public.contains(location) ||
          AppRoutes.onboarding.contains(location);
      return blocked ? AppRoutes.home : null;
  }
}
