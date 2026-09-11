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

import 'package:http/http.dart' as http;

import '../base/common.dart';
import 'git_host.dart';

/// What a host answered when asked to start a device login.
class DeviceAuthorization {
  /// The answer to one `requestCode` call against [DeviceFlow.codeEndpoint].
  const DeviceAuthorization({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    this.verificationUriComplete,
    required this.interval,
    required this.expiresIn,
  });

  /// The code [DeviceFlow.poll] trades in, never shown to the user.
  final String deviceCode;

  /// The code the user reads and enters in their browser.
  final String userCode;

  /// Where the user approves [userCode].
  final String verificationUri;

  /// [verificationUri] with [userCode] already filled in, when the host
  /// offers one: following it skips retyping the code by hand.
  final String? verificationUriComplete;

  /// How long to wait between one [DeviceFlow.poll] and the next.
  final Duration interval;

  /// How long [userCode] stays valid for.
  final Duration expiresIn;
}

/// What one [DeviceFlow.poll] call found.
///
/// Sealed so `dpw login`'s wait loop is forced, by the compiler, to decide
/// what every one of these means, rather than falling through a default
/// case if the host ever adds one RFC 8628 does not already name.
sealed class DevicePollResult {
  const DevicePollResult();
}

/// The user approved the login: [accessToken] is theirs to use once.
class DevicePollGranted extends DevicePollResult {
  /// Carries the [accessToken] the host minted.
  const DevicePollGranted(this.accessToken);

  /// The access token `dpw login` trades with dpw's backend for a session.
  final String accessToken;
}

/// The user has not answered yet: poll again after the interval.
class DevicePollPending extends DevicePollResult {
  /// The one instance this case ever needs.
  const DevicePollPending();
}

/// Polling is running ahead of what the host allows: back off before the
/// next attempt.
class DevicePollSlowDown extends DevicePollResult {
  /// The one instance this case ever needs.
  const DevicePollSlowDown();
}

/// The user declined the login.
class DevicePollDenied extends DevicePollResult {
  /// The one instance this case ever needs.
  const DevicePollDenied();
}

/// [DeviceAuthorization.userCode] expired before it was approved.
class DevicePollExpired extends DevicePollResult {
  /// The one instance this case ever needs.
  const DevicePollExpired();
}

/// One host's OAuth Device Authorization Grant (RFC 8628): request a code,
/// show it to the user, poll until they approve it in their browser.
///
/// A new host joins by filling in [codeEndpoint], [tokenEndpoint] and
/// [scope]; [requestCode] and [poll] are the same request/response shape
/// for every host that follows the RFC, so they live here once.
abstract class DeviceFlow {
  /// Talks to [host] over [_httpClient], identifying `dpw login` as
  /// [_clientId].
  const DeviceFlow(this.host, this._httpClient, this._clientId);

  /// Which host this flow logs into.
  final GitHost host;

  final http.Client _httpClient;
  final String _clientId;

  /// Where a device code is requested from.
  Uri get codeEndpoint;

  /// Where an approved device code is traded for an access token.
  Uri get tokenEndpoint;

  /// The access this flow asks the user to grant.
  String get scope;

  /// Starts a login: the user reads [DeviceAuthorization.userCode] and this
  /// call's caller [poll]s until they enter it.
  Future<DeviceAuthorization> requestCode() async {
    final response = await _httpClient.post(
      codeEndpoint,
      headers: const {'Accept': 'application/json'},
      body: {'client_id': _clientId, 'scope': scope},
    );
    if (response.statusCode != 200) {
      throwToolExit('dpw: ${host.label} refused to start the login (HTTP ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DeviceAuthorization(
      deviceCode: body['device_code'] as String,
      userCode: body['user_code'] as String,
      verificationUri: body['verification_uri'] as String,
      verificationUriComplete: body['verification_uri_complete'] as String?,
      interval: Duration(seconds: (body['interval'] as int?) ?? 5),
      expiresIn: Duration(seconds: body['expires_in'] as int),
    );
  }

  /// Asks once whether [deviceCode] has been approved yet.
  Future<DevicePollResult> poll(String deviceCode) async {
    final response = await _httpClient.post(
      tokenEndpoint,
      headers: const {'Accept': 'application/json'},
      body: {
        'client_id': _clientId,
        'device_code': deviceCode,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      },
    );

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throwToolExit('dpw: ${host.label} answered the login poll with something other than JSON.');
    }

    if (body['access_token'] case final String token) return DevicePollGranted(token);

    return switch (body['error'] as String?) {
      'authorization_pending' => const DevicePollPending(),
      'slow_down' => const DevicePollSlowDown(),
      'access_denied' => const DevicePollDenied(),
      'expired_token' => const DevicePollExpired(),
      _ => throwToolExit('dpw: ${host.label} answered the login poll unexpectedly: ${response.body}'),
    };
  }
}

/// Logs into github.com.
class GitHubDeviceFlow extends DeviceFlow {
  /// Identifies `dpw login` to GitHub as [clientId].
  GitHubDeviceFlow({required http.Client httpClient, required String clientId})
    : super(GitHost.github, httpClient, clientId);

  @override
  Uri get codeEndpoint => Uri.https('github.com', '/login/device/code');

  @override
  Uri get tokenEndpoint => Uri.https('github.com', '/login/oauth/access_token');

  @override
  String get scope => 'read:user';
}

/// Logs into [gitlabBaseUrl].
class GitLabDeviceFlow extends DeviceFlow {
  /// Identifies `dpw login` to [gitlabBaseUrl] as [clientId].
  GitLabDeviceFlow({required http.Client httpClient, required String clientId, required this.gitlabBaseUrl})
    : super(GitHost.gitlab, httpClient, clientId);

  /// Where this GitLab instance lives: `https://gitlab.com` unless
  /// self-managed.
  final String gitlabBaseUrl;

  @override
  Uri get codeEndpoint => Uri.parse('$gitlabBaseUrl/oauth/authorize_device');

  @override
  Uri get tokenEndpoint => Uri.parse('$gitlabBaseUrl/oauth/token');

  @override
  String get scope => 'read_user';
}
