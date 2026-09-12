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

import 'package:http/http.dart' as http;
import 'package:interact/interact.dart' as interact;

import '../auth/device_flow.dart';
import '../auth/git_host.dart';
import '../auth/session_store.dart';
import '../base/common.dart';
import '../globals.dart' as globals;
import '../runner/injectable_command.dart';

/// Links this machine to a injectable account through GitHub or GitLab.
///
/// Runs an OAuth Device Authorization Grant against whichever host is
/// chosen: a code and a link are shown, the browser opens on its own, and
/// this waits until the login is approved there. The provider is never
/// asked for more than who its token belongs to; injectable's backend is the one
/// place that identity is turned into a session, stored at
/// [globals.credentialsPath] for every other command to read.
class LoginCommand extends InjectableCommand {
  @override
  final name = 'login';

  @override
  final description = 'Links this machine to a injectable account through GitHub or GitLab.';

  @override
  bool get requiresAuthentication => false;

  /// Registers `--provider`.
  LoginCommand() {
    argParser.addOption('provider', allowed: const ['github', 'gitlab'], help: 'Skips the menu, asking on this host.');
  }

  @override
  Future<InjectableCommandResult> runCommand() async {
    final host = _resolveHost();
    final httpClient = http.Client();
    try {
      final flow = _flowFor(host, httpClient);

      final authorization = await flow.requestCode();
      globals.logger.printStatus('First, your one-time code: ${authorization.userCode}');

      final link = authorization.verificationUriComplete ?? authorization.verificationUri;
      globals.logger.printStatus('Opening $link in your browser to confirm it...');
      _tryOpenBrowser(link);

      final accessToken = await _awaitApproval(flow, authorization);
      final session = await _exchangeForSession(httpClient: httpClient, host: host, accessToken: accessToken);

      SessionStore(globals.credentialsPath).save(session);
      globals.logger.printStatus('injectable: logged in as ${session.login} on ${host.label}.');

      return const InjectableCommandResult.success();
    } finally {
      httpClient.close();
    }
  }

  GitHost _resolveHost() {
    if (GitHost.parse(argResults?['provider'] as String?) case final GitHost named) return named;

    if (!stdin.hasTerminal) {
      throwToolExit('injectable: pass --provider github|gitlab when there is no terminal to ask on.');
    }

    final picked = interact.Select(
      prompt: 'Which host is your injectable account linked through?',
      options: const ['GitHub', 'GitLab'],
    ).interact();
    return GitHost.values[picked];
  }

  DeviceFlow _flowFor(GitHost host, http.Client httpClient) {
    return switch (host) {
      GitHost.github => GitHubDeviceFlow(
        httpClient: httpClient,
        clientId:
            globals.githubOAuthClientId ??
            throwToolExit(
              'injectable: INJECTABLE_GITHUB_CLIENT_ID is not set; `injectable login` cannot reach GitHub without it.',
            ),
      ),
      GitHost.gitlab => GitLabDeviceFlow(
        httpClient: httpClient,
        clientId:
            globals.gitlabOAuthClientId ??
            throwToolExit(
              'injectable: INJECTABLE_GITLAB_CLIENT_ID is not set; `injectable login` cannot reach GitLab without it.',
            ),
        gitlabBaseUrl: globals.gitlabOAuthBaseUrl,
      ),
    };
  }

  Future<String> _awaitApproval(DeviceFlow flow, DeviceAuthorization authorization) async {
    final deadline = DateTime.now().add(authorization.expiresIn);
    var interval = authorization.interval;

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(interval);

      switch (await flow.poll(authorization.deviceCode)) {
        case DevicePollGranted(:final accessToken):
          return accessToken;
        case DevicePollPending():
          continue;
        case DevicePollSlowDown():
          interval += const Duration(seconds: 5);
        case DevicePollDenied():
          throwToolExit('injectable: login was declined.');
        case DevicePollExpired():
          throwToolExit('injectable: the login code expired before it was approved. Run `injectable login` again.');
      }
    }

    throwToolExit('injectable: timed out waiting for the login to be approved. Run `injectable login` again.');
  }

  Future<StoredSession> _exchangeForSession({
    required http.Client httpClient,
    required GitHost host,
    required String accessToken,
  }) async {
    final response = await httpClient.post(
      Uri.parse('${globals.backendBaseUrl}/v1/auth/session'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'provider': host.name, 'access_token': accessToken}),
    );

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throwToolExit('injectable: the backend answered the login with something other than JSON.');
    }

    if (response.statusCode != 200) {
      throwToolExit('injectable: ${body['error'] ?? 'login failed (HTTP ${response.statusCode}).'}');
    }

    final token = body['token'] as String;
    final refreshToken = body['refresh_token'] as String?;
    final user = body['user'] as Map<String, dynamic>;
    return StoredSession(token: token, refreshToken: refreshToken, host: host, login: user['login'] as String);
  }

  /// Best-effort: [url] and its code are already printed, so a browser that
  /// fails to open on its own is not this command's failure.
  void _tryOpenBrowser(String url) {
    try {
      if (Platform.isMacOS) {
        Process.runSync('open', [url]);
      } else if (Platform.isLinux) {
        Process.runSync('xdg-open', [url]);
      } else if (Platform.isWindows) {
        Process.runSync('cmd', ['/c', 'start', '', url]);
      }
    } catch (_) {
      return;
    }
  }
}
