import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare_mobile_application/iam/domain/model/account_type.dart';
import 'package:petcare_mobile_application/iam/infrastructure/auth_api.dart';
import 'package:petcare_mobile_application/iam/infrastructure/session_storage.dart';
import 'package:petcare_mobile_application/shared/infrastructure/api_client.dart';

void main() {
  AuthApi apiWith(MockClientHandler handler) => AuthApi(
    ApiClient(
      baseUrl: 'http://api.test/api/v1',
      tokenProvider: InMemorySessionStorage(),
      httpClient: MockClient(handler),
    ),
  );

  test('sign-up envía email, password y accountType del backend', () async {
    late Map<String, dynamic> body;
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/authentication/sign-up');
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 201);
    });

    await api.signUp(email: 'a@b.pe', password: 'Secreta123', accountType: AccountType.clinic);

    expect(body, {'email': 'a@b.pe', 'password': 'Secreta123', 'accountType': 'CLINIC'});
  });

  test('sign-in convierte AuthenticatedUserResource en UserSession', () async {
    final api = apiWith(
      (_) async => http.Response(
        jsonEncode({
          'userId': 5,
          'accountId': 9,
          'accountType': 'PET_OWNER',
          'email': 'roberto@example.com',
          'roles': ['ROLE_PET_OWNER'],
          'mustChangePassword': false,
          'token': 'jwt',
        }),
        200,
      ),
    );

    final session = await api.signIn(email: 'roberto@example.com', password: 'x');

    expect(session.userId, 5);
    expect(session.accountId, 9);
    expect(session.accountType, AccountType.petOwner);
    expect(session.isPetOwner, isTrue);
    expect(session.token, 'jwt');
  });

  test('restore usa /users/me (UserResource trae id, no userId)', () async {
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/users/me');
      return http.Response(
        jsonEncode({
          'id': 3,
          'accountId': 20,
          'accountType': 'CLINIC',
          'email': 'vet@vetsur.pe',
          'accessRole': 'MEMBER',
          'status': 'ACTIVE',
          'roles': ['ROLE_VETERINARIAN'],
          'mustChangePassword': true,
        }),
        200,
      );
    });

    final session = await api.restore('saved-token');

    expect(session.userId, 3);
    expect(session.token, 'saved-token');
    expect(session.isClinicMember, isTrue);
    expect(session.mustChangePassword, isTrue);
  });
}
