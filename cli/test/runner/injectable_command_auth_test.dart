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

import 'package:cli/runner.dart' as runner;
import 'package:cli/src/auth/git_host.dart';
import 'package:cli/src/auth/session_store.dart';
import 'package:cli/src/base/context.dart';
import 'package:cli/src/base/logger.dart';
import 'package:cli/src/globals.dart';
import 'package:cli/src/runner/injectable_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A JWT-shaped token carrying [exp] as its only claim, signature
/// unchecked: nothing this test drives ever verifies one, only reads the
/// payload back out.
String _fakeJwt(DateTime exp) {
  String segment(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${segment({'alg': 'none'})}.${segment({'exp': exp.millisecondsSinceEpoch ~/ 1000})}.signature';
}

void main() {
  test('a command that requires authentication refuses to run without a stored session', () async {
    var ran = false;
    final buffer = BufferLogger();

    final exitCode = await runner.run(
      ['fake'],
      () => [_FakeCommand(requiresAuthentication: true, onRun: () => ran = true)],
      overrides: <Type, Generator>{
        Logger: () => buffer,
        StoredCredentials: () => const StoredCredentials(null),
        RemoteUpdateCheckInterval: () => const RemoteUpdateCheckInterval(Duration(days: 365 * 100)),
      },
    );

    expect(exitCode, isNot(0));
    expect(ran, isFalse);
    expect(buffer.errorText, contains('not logged in'));
  });

  test('a command that requires authentication runs once a session is stored', () async {
    var ran = false;
    final buffer = BufferLogger();

    final exitCode = await runner.run(
      ['fake'],
      () => [_FakeCommand(requiresAuthentication: true, onRun: () => ran = true)],
      overrides: <Type, Generator>{
        Logger: () => buffer,
        StoredCredentials: () =>
            const StoredCredentials(StoredSession(token: 't', host: GitHost.github, login: 'octocat')),
        RemoteUpdateCheckInterval: () => const RemoteUpdateCheckInterval(Duration(days: 365 * 100)),
      },
    );

    expect(exitCode, 0);
    expect(ran, isTrue);
  });

  test('a command that opts out runs with no stored session, the way login and logout must', () async {
    var ran = false;
    final buffer = BufferLogger();

    final exitCode = await runner.run(
      ['fake'],
      () => [_FakeCommand(requiresAuthentication: false, onRun: () => ran = true)],
      overrides: <Type, Generator>{
        Logger: () => buffer,
        StoredCredentials: () => const StoredCredentials(null),
        RemoteUpdateCheckInterval: () => const RemoteUpdateCheckInterval(Duration(days: 365 * 100)),
      },
    );

    expect(exitCode, 0);
    expect(ran, isTrue);
  });

  test('a session close to expiry is renewed before the command runs, and the renewal is persisted', () async {
    final workspace = Directory.systemTemp.createTempSync('injectable_command_auth_test_');
    addTearDown(() => workspace.deleteSync(recursive: true));
    final credentialsPath = p.join(workspace.path, 'credentials');

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen(
      (request) => request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'token': 'new-jwt', 'refresh_token': 'refresh-2'}))
        ..close(),
    );

    var ran = false;
    final buffer = BufferLogger();

    final exitCode = await runner.run(
      ['fake'],
      () => [_FakeCommand(requiresAuthentication: true, onRun: () => ran = true)],
      overrides: <Type, Generator>{
        Logger: () => buffer,
        CredentialsPath: () => CredentialsPath(credentialsPath),
        BackendBaseUrl: () => BackendBaseUrl('http://${server.address.host}:${server.port}'),
        StoredCredentials: () => StoredCredentials(
          StoredSession(
            token: _fakeJwt(DateTime.now().add(const Duration(days: 1))),
            refreshToken: 'refresh-1',
            host: GitHost.github,
            login: 'octocat',
          ),
        ),
        RemoteUpdateCheckInterval: () => const RemoteUpdateCheckInterval(Duration(days: 365 * 100)),
      },
    );

    expect(exitCode, 0);
    expect(ran, isTrue);
    expect(SessionStore(credentialsPath).read()?.token, 'new-jwt');
    expect(SessionStore(credentialsPath).read()?.refreshToken, 'refresh-2');
  });

  test(
    'an expired session the backend refuses to renew refuses to run, telling the developer to log in again',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((request) => (request.response..statusCode = HttpStatus.unauthorized).close());

      var ran = false;
      final buffer = BufferLogger();

      final exitCode = await runner.run(
        ['fake'],
        () => [_FakeCommand(requiresAuthentication: true, onRun: () => ran = true)],
        overrides: <Type, Generator>{
          Logger: () => buffer,
          BackendBaseUrl: () => BackendBaseUrl('http://${server.address.host}:${server.port}'),
          StoredCredentials: () => StoredCredentials(
            StoredSession(
              token: _fakeJwt(DateTime.now().subtract(const Duration(days: 1))),
              refreshToken: 'refresh-1',
              host: GitHost.github,
              login: 'octocat',
            ),
          ),
          RemoteUpdateCheckInterval: () => const RemoteUpdateCheckInterval(Duration(days: 365 * 100)),
        },
      );

      expect(exitCode, isNot(0));
      expect(ran, isFalse);
      expect(buffer.errorText, contains('session expired'));
    },
  );
}

class _FakeCommand extends InjectableCommand {
  _FakeCommand({required bool requiresAuthentication, required this.onRun})
    : _requiresAuthentication = requiresAuthentication;

  final bool _requiresAuthentication;
  final void Function() onRun;

  @override
  final name = 'fake';

  @override
  final description = 'A fake command, only ever run inside this test.';

  @override
  bool get requiresAuthentication => _requiresAuthentication;

  @override
  Future<InjectableCommandResult> runCommand() async {
    onRun();
    return const InjectableCommandResult.success();
  }
}
