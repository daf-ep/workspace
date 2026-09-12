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
import 'package:cli/src/auth/session_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory project;
  late String binPath;
  late String credentialsPath;

  setUp(() {
    project = Directory.systemTemp.createTempSync('injectable_logout_command_e2e_');
    binPath = p.join(Directory.current.path, 'bin', 'injectable.dart');
    credentialsPath = p.join(project.path, 'credentials');
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('logout revokes the stored refresh token on the backend, then clears the local file', () async {
    SessionStore(
      credentialsPath,
    ).save(const StoredSession(token: 't', refreshToken: 'refresh-1', host: GitHost.github, login: 'octocat'));

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    String? revokedToken;
    server.listen((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
      revokedToken = body['refresh_token'] as String?;
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'revoked'}));
      await request.response.close();
    });

    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', binPath, 'logout'],
      workingDirectory: project.path,
      environment: {
        'INJECTABLE_CREDENTIALS_PATH': credentialsPath,
        'INJECTABLE_BACKEND_URL': 'http://${server.address.host}:${server.port}',
        'INJECTABLE_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000',
      },
    );

    expect(result.exitCode, 0);
    expect(revokedToken, 'refresh-1');
    expect(File(credentialsPath).existsSync(), isFalse);
  });

  test('logout still clears the local session when the backend cannot be reached', () async {
    SessionStore(
      credentialsPath,
    ).save(const StoredSession(token: 't', refreshToken: 'refresh-1', host: GitHost.github, login: 'octocat'));

    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', binPath, 'logout'],
      workingDirectory: project.path,
      environment: {
        'INJECTABLE_CREDENTIALS_PATH': credentialsPath,
        'INJECTABLE_BACKEND_URL': 'http://127.0.0.1:1',
        'INJECTABLE_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000',
      },
    );

    expect(result.exitCode, 0);
    expect(File(credentialsPath).existsSync(), isFalse);
  });

  test('logout with no refresh token stored never calls the backend', () async {
    SessionStore(credentialsPath).save(const StoredSession(token: 't', host: GitHost.github, login: 'octocat'));

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) => fail('should never call the backend without a refresh token'));

    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', binPath, 'logout'],
      workingDirectory: project.path,
      environment: {
        'INJECTABLE_CREDENTIALS_PATH': credentialsPath,
        'INJECTABLE_BACKEND_URL': 'http://${server.address.host}:${server.port}',
        'INJECTABLE_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000',
      },
    );

    expect(result.exitCode, 0);
    expect(File(credentialsPath).existsSync(), isFalse);
  });

  test('logout with nothing stored is still a no-op success', () async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', binPath, 'logout'],
      workingDirectory: project.path,
      environment: {
        'INJECTABLE_CREDENTIALS_PATH': credentialsPath,
        'INJECTABLE_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000',
      },
    );

    expect(result.exitCode, 0);
    expect(result.stdout, contains('was not logged in'));
  });
}
