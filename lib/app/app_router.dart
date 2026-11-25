import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../clinical_attention/presentation/views/clinical_history_view.dart';
import '../clinical_attention/presentation/views/consultation_detail_view.dart';
import '../clinical_attention/presentation/views/consultation_workspace_view.dart';
import '../clinical_attention/presentation/views/consultations_view.dart';
import '../clinical_attention/presentation/views/new_consultation_view.dart';
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

  // Un id que no es número (enlace mal escrito) no existe: 0 hace que la API responda 404.
  int idOf(GoRouterState state, String name) => int.tryParse(state.pathParameters[name]!) ?? 0;
  int petIdOf(GoRouterState state) => idOf(state, 'petId');
  int consultationIdOf(GoRouterState state) => idOf(state, 'consultationId');

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
                      GoRoute(
                        path: 'history',
                        parentNavigatorKey: rootKey,
                        builder: (context, state) => ClinicalHistoryView(
                          petId: petIdOf(state),
                          onOpen: (consultation) => context.push(
                            AppRoutes.petConsultation(consultation.petId, consultation.id),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'consultations/:consultationId',
                        parentNavigatorKey: rootKey,
                        builder: (_, state) => ConsultationDetailView(
                          petId: petIdOf(state),
                          consultationId: consultationIdOf(state),
                        ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.consultations,
                builder: (context, _) => ConsultationsView(
                  clinicId: profiles.clinicId,
                  onOpen: (consultation) =>
                      context.push(AppRoutes.consultation(consultation.id)),
                  onRegister: (petId) => context.push(AppRoutes.newConsultation(petId: petId)),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newConsultation(),
        builder: (context, state) => NewConsultationView(
          clinicId: profiles.clinicId,
          petId: int.tryParse(state.uri.queryParameters['petId'] ?? ''),
          onCreated: (id) => context.pushReplacement(AppRoutes.consultation(id)),
        ),
      ),
      GoRoute(
        path: '/consultations/:consultationId',
        builder: (_, state) => ConsultationWorkspaceView(consultationId: consultationIdOf(state)),
      ),
      GoRoute(
        path: '/patients/:petId',
        builder: (_, state) => PetDetailView(petId: petIdOf(state)),
        routes: [
          GoRoute(
            path: 'history',
            builder: (context, state) => ClinicalHistoryView(
              petId: petIdOf(state),
              onOpen: (consultation) => context.push(AppRoutes.consultation(consultation.id)),
              onRegister: () =>
                  context.push(AppRoutes.newConsultation(petId: petIdOf(state))),
            ),
          ),
        ],
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
      // 6. Registrar consultas: solo el veterinario (la API exige ROLE_VETERINARIAN).
      if (location.startsWith(AppRoutes.consultations) && !session.isVeterinarian) {
        return AppRoutes.home;
      }
      return null;
  }
}
