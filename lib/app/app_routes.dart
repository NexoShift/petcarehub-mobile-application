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
  static const consultations = '/consultations';

  // Pantallas completas (sin barra inferior).
  static const newPet = '/pets/new';
  static String pet(int petId) => '/pets/$petId';
  static String editPet(int petId) => '/pets/$petId/edit';
  static String patient(int petId) => '/patients/$petId';

  // Clinical Attention: el dueño solo lee; el veterinario registra.
  static String petHistory(int petId) => '/pets/$petId/history';
  static String petConsultation(int petId, int consultationId) =>
      '/pets/$petId/consultations/$consultationId';
  static String patientHistory(int petId) => '/patients/$petId/history';
  static String consultation(int consultationId) => '/consultations/$consultationId';
  static String newConsultation({int? petId}) =>
      petId == null ? '/consultations/new' : '/consultations/new?petId=$petId';

  /// Pantallas que se ven sin sesión.
  static const public = {welcome, signIn, signUp};

  /// Paso 2 del onboarding.
  static const onboarding = {completePetOwner, completeClinic};
}
