/// Rutas de la app en un solo lugar (evita strings sueltos en las vistas).
class AppRoutes {
  const AppRoutes._();

  static const boot = '/boot';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const changePassword = '/change-password';
  static const completePetOwner = '/complete-profile/pet-owner';
  static const completeClinic = '/complete-profile/clinic';

  // Pestañas de la barra inferior.
  static const home = '/home';
  static const pets = '/pets';
  static const profile = '/profile';

  // Pantallas completas (sin barra inferior).
  static const newPet = '/pets/new';
  static String pet(int petId) => '/pets/$petId';
  static String editPet(int petId) => '/pets/$petId/edit';
  static String patient(int petId) => '/patients/$petId';

  /// Pantallas que se ven sin sesión.
  static const public = {welcome, signIn, signUp};

  /// Paso 2 del onboarding.
  static const onboarding = {completePetOwner, completeClinic};
}
