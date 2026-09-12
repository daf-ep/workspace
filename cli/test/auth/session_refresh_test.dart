// Copyright (C) 2026 Fiber
//
// This software is licensed under the PolyForm Noncommercial License 1.0.0. A
// copy of it is available at
// https://polyformproject.org/licenses/noncommercial/1.0.0, and in the LICENSE
// file at the root of this repository.
//
// What you may do:
// - Use, study, and modify this software for any noncommercial purpose,
//   including personal use, research, education, and use by a charitable,
//   public research, public safety, health, environmental, or government
//   institution.
// - Distribute copies of it, with or without your changes, for those same
//   noncommercial purposes.
//
// What you may not do:
// - Use this software, or a modified or combined version of it, in a
//   commercial product or service, or for any other commercial purpose.
// - Sublicense it, or transfer your licence to someone else.
//
// What you must do in return:
// - Keep this notice on every file you received it on.
//
// Disclaimer:
// AS FAR AS THE LAW ALLOWS, THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
// OR CONDITION OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
// NON-INFRINGEMENT. IN NO EVENT SHALL FIBER BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING BUT NOT
// LIMITED TO LOSS OF USE, DATA, PROFITS, OR BUSINESS INTERRUPTION) ARISING OUT
// OF OR RELATED TO THESE TERMS OR THE USE OR NATURE OF THE SOFTWARE, UNDER ANY
// KIND OF LEGAL CLAIM.
//
// This header is a summary written for convenience. Where it differs from the
// LICENSE file, the LICENSE file governs.

import 'dart:convert';
import 'dart:io';

import 'package:cli/src/auth/git_host.dart';
import 'package:cli/src/auth/session_refresh.dart';
import 'package:cli/src/auth/session_store.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// A JWT-shaped token carrying [exp] as its only claim, signature
/// unchecked: [ensureFreshSession] never verifies one, only reads the
/// payload back out.
String _fakeJwt(DateTime exp) {
  String segment(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${segment({'alg': 'none'})}.${segment({'exp': exp.millisecondsSinceEpoch ~/ 1000})}.signature';
}

const _session = StoredSession(token: 'irrelevant', host: GitHost.github, login: 'octocat');

void main() {
  late http.Client httpClient;

  setUp(() => httpClient = http.Client());
  tearDown(() => httpClient.close());

  test('a token far from expiry is left as is, no request made', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) => fail('should never call the backend for a token this fresh'));

    final result = await ensureFreshSession(
      httpClient: httpClient,
      backendBaseUrl: 'http://${server.address.host}:${server.port}',
      session: _session.copyWith(token: _fakeJwt(DateTime.now().add(const Duration(days: 89)))),
      onRenewed: (_) => fail('should never renew a token this fresh'),
    );

    expect(result, isTrue);
  });

  test('a token that is not a JWT is left as is, guessed at as neither fresh nor expired', () async {
    final result = await ensureFreshSession(
      httpClient: httpClient,
      backendBaseUrl: 'http://unused.invalid',
      session: _session,
      onRenewed: (_) => fail('should never try to renew an unparseable token'),
    );

    expect(result, isTrue);
  });

  test('close to expiry with a refresh token, the backend grants: renews and reports fresh', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
      expect(body['refresh_token'], 'refresh-1');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'token': 'new-jwt', 'refresh_token': 'refresh-2'}));
      await request.response.close();
    });

    StoredSession? renewed;
    final result = await ensureFreshSession(
      httpClient: httpClient,
      backendBaseUrl: 'http://${server.address.host}:${server.port}',
      session: _session.copyWith(
        token: _fakeJwt(DateTime.now().add(const Duration(days: 1))),
        refreshToken: 'refresh-1',
      ),
      onRenewed: (session) => renewed = session,
    );

    expect(result, isTrue);
    expect(renewed?.token, 'new-jwt');
    expect(renewed?.refreshToken, 'refresh-2');
  });

  test('already expired, the backend denies the refresh token: reports expired', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) => (request.response..statusCode = HttpStatus.unauthorized).close());

    final result = await ensureFreshSession(
      httpClient: httpClient,
      backendBaseUrl: 'http://${server.address.host}:${server.port}',
      session: _session.copyWith(
        token: _fakeJwt(DateTime.now().subtract(const Duration(days: 1))),
        refreshToken: 'refresh-1',
      ),
      onRenewed: (_) => fail('a denied refresh should never call onRenewed'),
    );

    expect(result, isFalse);
  });

  test('already expired, no refresh token stored: reports expired without a request', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) => fail('nothing to send without a refresh token'));

    final result = await ensureFreshSession(
      httpClient: httpClient,
      backendBaseUrl: 'http://${server.address.host}:${server.port}',
      session: _session.copyWith(token: _fakeJwt(DateTime.now().subtract(const Duration(days: 1)))),
      onRenewed: (_) => fail('nothing to renew without a refresh token'),
    );

    expect(result, isFalse);
  });

  test('close to expiry but the backend is unreachable: still reports fresh, on the still-valid token', () async {
    final result = await ensureFreshSession(
      httpClient: httpClient,
      backendBaseUrl: 'http://unused.invalid',
      session: _session.copyWith(
        token: _fakeJwt(DateTime.now().add(const Duration(hours: 1))),
        refreshToken: 'refresh-1',
      ),
      onRenewed: (_) => fail('a failed renewal should never call onRenewed'),
    );

    expect(result, isTrue);
  });
}

extension on StoredSession {
  StoredSession copyWith({String? token, String? refreshToken}) => StoredSession(
    token: token ?? this.token,
    refreshToken: refreshToken ?? this.refreshToken,
    host: host,
    login: login,
  );
}
