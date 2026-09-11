// Copyright (C) 2026 Fiber
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
//
// What you may do:
// - Use this software for any purpose, including commercially, and build and
//   sell your own products on top of it.
// - Change it, and create new works based on it.
// - Distribute copies of it, with or without your changes.
// - Combine it with files under any other licence, proprietary ones included,
//   and licence that larger work on your own terms.
//
// What you must do in return:
// - Keep this notice on every file you received it on.
// - Publish, under these same terms, the source of every file covered by them
//   that you distribute, including the ones you changed, so that whoever
//   receives your version can obtain that source.
// - Leave Fiber out of it: the name "Fiber", its branding, its logos and its
//   trademarks may not be used to endorse or promote what you build, and this
//   licence grants no right to them.
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
import '../runner/dpw_command.dart';

/// Links this machine to a dpw account through GitHub or GitLab.
///
/// Runs an OAuth Device Authorization Grant against whichever host is
/// chosen: a code and a link are shown, the browser opens on its own, and
/// this waits until the login is approved there. The provider is never
/// asked for more than who its token belongs to; dpw's backend is the one
/// place that identity is turned into a session, stored at
/// [globals.credentialsPath] for every other command to read.
class LoginCommand extends DpwCommand {
  @override
  final name = 'login';

  @override
  final description = 'Links this machine to a dpw account through GitHub or GitLab.';

  @override
  bool get requiresAuthentication => false;

  /// Registers `--provider`.
  LoginCommand() {
    argParser.addOption('provider', allowed: const ['github', 'gitlab'], help: 'Skips the menu, asking on this host.');
  }

  @override
  Future<DpwCommandResult> runCommand() async {
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
      globals.logger.printStatus('dpw: logged in as ${session.login} on ${host.label}.');

      return const DpwCommandResult.success();
    } finally {
      httpClient.close();
    }
  }

  GitHost _resolveHost() {
    if (GitHost.parse(argResults?['provider'] as String?) case final GitHost named) return named;

    if (!stdin.hasTerminal) {
      throwToolExit('dpw: pass --provider github|gitlab when there is no terminal to ask on.');
    }

    final picked = interact.Select(
      prompt: 'Which host is your dpw account linked through?',
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
            throwToolExit('dpw: DPW_GITHUB_CLIENT_ID is not set; `dpw login` cannot reach GitHub without it.'),
      ),
      GitHost.gitlab => GitLabDeviceFlow(
        httpClient: httpClient,
        clientId:
            globals.gitlabOAuthClientId ??
            throwToolExit('dpw: DPW_GITLAB_CLIENT_ID is not set; `dpw login` cannot reach GitLab without it.'),
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
          throwToolExit('dpw: login was declined.');
        case DevicePollExpired():
          throwToolExit('dpw: the login code expired before it was approved. Run `dpw login` again.');
      }
    }

    throwToolExit('dpw: timed out waiting for the login to be approved. Run `dpw login` again.');
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
      throwToolExit('dpw: the backend answered the login with something other than JSON.');
    }

    if (response.statusCode != 200) {
      throwToolExit('dpw: ${body['error'] ?? 'login failed (HTTP ${response.statusCode}).'}');
    }

    final token = body['token'] as String;
    final user = body['user'] as Map<String, dynamic>;
    return StoredSession(token: token, host: host, login: user['login'] as String);
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
