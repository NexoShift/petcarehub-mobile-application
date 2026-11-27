import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../clinical_attention/application/consultation_workspace_store.dart';
import '../clinical_attention/application/consultations_store.dart';
import '../clinical_attention/application/outbound_services/external_profiles_service.dart';
import '../clinical_attention/application/patient_directory_store.dart';
import '../clinical_attention/domain/repositories/consultations_repository.dart';
import '../clinical_attention/infrastructure/acl/profiles_acl_service.dart';
import '../clinical_attention/infrastructure/consultations_api.dart';
import '../iam/application/iam_store.dart';
import '../iam/domain/repositories/auth_repository.dart';
import '../iam/infrastructure/auth_api.dart';
import '../iam/infrastructure/session_storage.dart';
import '../profiles/application/clinic_patients_store.dart';
import '../profiles/application/pets_store.dart';
import '../profiles/application/profiles_store.dart';
import '../profiles/domain/repositories/pets_repository.dart';
import '../profiles/domain/repositories/profiles_repository.dart';
import '../profiles/infrastructure/pets_api.dart';
import '../profiles/infrastructure/profiles_api.dart';
import '../shared/infrastructure/api_client.dart';
import '../shared/infrastructure/image_picker_service.dart';
import 'app.dart';
import 'app_router.dart';

/// Composition root: aquí, y solo aquí, se crean las implementaciones
/// concretas (http, *Api, image_picker) y se conectan con los stores.
///
/// Los tests llaman a [buildApp] con repositorios falsos.
Widget buildApp({
  SessionStorage? storage,
  AuthRepository? authRepository,
  ProfilesRepository? profilesRepository,
  PetsRepository? petsRepository,
  ConsultationsRepository? consultationsRepository,
  ExternalProfilesService? externalProfilesService,
  ImagePickerService? imagePicker,
  bool useGoogleFonts = true,
}) {
  final sessionStorage = storage ?? SessionStorage();
  final apiClient = ApiClient(httpClient: http.Client(), tokenProvider: sessionStorage);

  final iamStore = IamStore(
    repository: authRepository ?? AuthApi(apiClient),
    storage: sessionStorage,
  );
  final profilesRepo = profilesRepository ?? ProfilesApi(apiClient);
  final profilesStore = ProfilesStore(repository: profilesRepo, iamStore: iamStore);
  final petsRepo = petsRepository ?? PetsApi(apiClient);
  final petsStore = PetsStore(repository: petsRepo);
  final patientsStore = ClinicPatientsStore(repository: petsRepo);
  final consultationsRepo = consultationsRepository ?? ConsultationsApi(apiClient);
  final consultationsStore = ConsultationsStore(repository: consultationsRepo);
  final workspaceStore = ConsultationWorkspaceStore(
    repository: consultationsRepo,
    consultations: consultationsStore,
  );
  final directoryStore = PatientDirectoryStore(
    profiles:
        externalProfilesService ??
        ProfilesAclService(pets: petsRepo, profiles: profilesRepo, client: apiClient),
  );

  // Al cerrar sesión no deben quedar datos del usuario anterior en memoria.
  iamStore.addListener(() {
    if (!iamStore.isAuthenticated) {
      petsStore.clear();
      patientsStore.clear();
      consultationsStore.clear();
      workspaceStore.clear();
      directoryStore.clear();
    }
  });

  final GoRouter router = createRouter(iam: iamStore, profiles: profilesStore);

  return MultiProvider(
    providers: [
      Provider<ImagePickerService>.value(value: imagePicker ?? DeviceImagePickerService()),
      ChangeNotifierProvider.value(value: iamStore),
      ChangeNotifierProvider.value(value: profilesStore),
      ChangeNotifierProvider.value(value: petsStore),
      ChangeNotifierProvider.value(value: patientsStore),
      ChangeNotifierProvider.value(value: consultationsStore),
      ChangeNotifierProvider.value(value: workspaceStore),
      ChangeNotifierProvider.value(value: directoryStore),
    ],
    child: PetCareHubApp(router: router, useGoogleFonts: useGoogleFonts),
  );
}
