import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare_mobile_application/shared/domain/api_error.dart';
import 'package:petcare_mobile_application/shared/infrastructure/api_client.dart';
import 'package:petcare_mobile_application/shared/infrastructure/token_provider.dart';

class _Tokens implements TokenProvider {
  _Tokens(this.token);

  @override
  String? token;
  int unauthorizedCalls = 0;

  @override
  void onUnauthorized() => unauthorizedCalls++;
}

void main() {
  const base = 'http://api.test/api/v1';

  test('arma la URL y pone el Bearer cuando hay token', () async {
    late http.Request captured;
    final client = ApiClient(
      baseUrl: base,
      tokenProvider: _Tokens('abc'),
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 200);
      }),
    );

    final body = await client.get('/pet-owners', query: {'userId': '7'});

    expect(captured.url.toString(), '$base/pet-owners?userId=7');
    expect(captured.headers['Authorization'], 'Bearer abc');
    expect(body, {'ok': true});
  });

  test('no pone Authorization sin token y envía JSON en el POST', () async {
    late http.Request captured;
    final client = ApiClient(
      baseUrl: base,
      tokenProvider: _Tokens(null),
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('', 201);
      }),
    );

    await client.post('/authentication/sign-up', body: {'email': 'a@b.pe'});

    expect(captured.headers.containsKey('Authorization'), isFalse);
    expect(captured.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(captured.body), {'email': 'a@b.pe'});
  });

  test('convierte ErrorResource en ApiError con status, mensaje y detalles', () async {
    final client = ApiClient(
      baseUrl: base,
      tokenProvider: _Tokens(null),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 400,
            'error': 'Bad Request',
            'message': 'Invalid request data',
            'details': ['email: must be a well-formed email address'],
          }),
          400,
        ),
      ),
    );

    expect(
      () => client.post('/authentication/sign-up'),
      throwsA(
        isA<ApiError>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.message, 'message', 'Invalid request data')
            .having((e) => e.details, 'details', hasLength(1)),
      ),
    );
  });

  test('un 401 con token avisa que la sesión venció', () async {
    final tokens = _Tokens('expired');
    final client = ApiClient(
      baseUrl: base,
      tokenProvider: tokens,
      httpClient: MockClient((_) async => http.Response('', 401)),
    );

    await expectLater(client.get('/users/me'), throwsA(isA<ApiError>()));
    expect(tokens.unauthorizedCalls, 1);
  });

  test('un error de red se convierte en ApiError con status 0', () async {
    final client = ApiClient(
      baseUrl: base,
      tokenProvider: _Tokens(null),
      httpClient: MockClient((_) async => throw http.ClientException('offline')),
    );

    expect(
      () => client.get('/plans'),
      throwsA(isA<ApiError>().having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
    );
  });

  test('postMultipart envía los campos y omite los nulos', () async {
    late String body;
    final client = ApiClient(
      baseUrl: base,
      tokenProvider: _Tokens('abc'),
      httpClient: MockClient((request) async {
        body = request.body;
        expect(request.headers['content-type'], startsWith('multipart/form-data'));
        return http.Response('{}', 201);
      }),
    );

    await client.postMultipart('/pet-owners', {'firstName': 'Roberto', 'sex': null});

    expect(body, contains('name="firstName"'));
    expect(body, isNot(contains('name="sex"')));
  });
}
