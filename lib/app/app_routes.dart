/// Rutas de la app en un solo lugar (evita strings sueltos en las vistas).
class AppRoutes {
  const AppRoutes._();

  static const boot = '/boot';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const completePetOwner = '/complete-profile/pet-owner';
  static const completeClinic = '/complete-profile/clinic';
  static const home = '/home';

  /// Pantallas que se ven sin sesión.
  static const public = {welcome, signIn, signUp};

  /// Paso 2 del onboarding.
  static const onboarding = {completePetOwner, completeClinic};
}
