import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../iam/application/iam_store.dart';
import '../iam/domain/repositories/auth_repository.dart';
import '../iam/infrastructure/auth_api.dart';
import '../iam/infrastructure/session_storage.dart';
import '../profiles/application/profiles_store.dart';
import '../profiles/domain/repositories/profiles_repository.dart';
import '../profiles/infrastructure/profiles_api.dart';
import '../shared/infrastructure/api_client.dart';
import 'app.dart';
import 'app_router.dart';

/// Composition root: aquí, y solo aquí, se crean las implementaciones
/// concretas (http, AuthApi, ProfilesApi) y se conectan con los stores.
///
/// Los tests llaman a [buildApp] con repositorios falsos.
Widget buildApp({
  SessionStorage? storage,
  AuthRepository? authRepository,
  ProfilesRepository? profilesRepository,
  bool useGoogleFonts = true,
}) {
  final sessionStorage = storage ?? SessionStorage();
  final apiClient = ApiClient(httpClient: http.Client(), tokenProvider: sessionStorage);

  final iamStore = IamStore(
    repository: authRepository ?? AuthApi(apiClient),
    storage: sessionStorage,
  );
  final profilesStore = ProfilesStore(
    repository: profilesRepository ?? ProfilesApi(apiClient),
    iamStore: iamStore,
  );
  final GoRouter router = createRouter(iam: iamStore, profiles: profilesStore);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: iamStore),
      ChangeNotifierProvider.value(value: profilesStore),
    ],
    child: PetCareHubApp(router: router, useGoogleFonts: useGoogleFonts),
  );
}
