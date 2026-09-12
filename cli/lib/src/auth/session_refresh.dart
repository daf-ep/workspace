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

import 'session_store.dart';

/// How far ahead of a JWT's own expiry [ensureFreshSession] starts trying to
/// renew it: wide enough that a normal offline stretch, a laptop closed over
/// a weekend, still leaves room for the next successful attempt before
/// [token] actually stops being accepted.
const _refreshBuffer = Duration(days: 7);

/// Renews [session] in place when its JWT is close to expiring, and reports
/// whether the caller can keep going.
///
/// Reads [session.token]'s own `exp` claim rather than asking the backend:
/// this needs no network at all outside the narrow window before expiry,
/// which is what keeps every other authenticated command from paying for a
/// request it almost never needs. A token this cannot parse as a JWT, the
/// literal strings a test stores, is left untouched and treated as still
/// good: guessing at an unknown shape is worse than doing nothing.
///
/// Returns true when [session] is safe to use as is, whether because it
/// still has time left or because renewing it failed while it does. Returns
/// false only when [session]'s JWT has already expired and no refresh token
/// could replace it, the one case where the caller has nothing left to try
/// but `injectable login` again.
Future<bool> ensureFreshSession({
  required http.Client httpClient,
  required String backendBaseUrl,
  required StoredSession session,
  required void Function(StoredSession renewed) onRenewed,
}) async {
  final expiry = _jwtExpiry(session.token);
  if (expiry == null) return true;

  final now = DateTime.now();
  if (now.isBefore(expiry.subtract(_refreshBuffer))) return true;

  final renewed = await _tryRefresh(httpClient: httpClient, backendBaseUrl: backendBaseUrl, session: session);
  if (renewed != null) {
    onRenewed(renewed);
    return true;
  }

  return now.isBefore(expiry);
}

Future<StoredSession?> _tryRefresh({
  required http.Client httpClient,
  required String backendBaseUrl,
  required StoredSession session,
}) async {
  final refreshToken = session.refreshToken;
  if (refreshToken == null) return null;

  try {
    final response = await httpClient.post(
      Uri.parse('$backendBaseUrl/v1/auth/refresh'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String?;
    final newRefreshToken = body['refresh_token'] as String?;
    if (token == null || newRefreshToken == null) return null;

    return StoredSession(token: token, refreshToken: newRefreshToken, host: session.host, login: session.login);
  } catch (_) {
    return null;
  }
}

/// The `exp` claim inside [token]'s payload, read without verifying its
/// signature: `injectable` never holds the secret that would let it verify
/// one, it only needs this to decide whether to renew before the backend
/// itself would refuse the token. Null for anything that is not a
/// three-part JWT, or whose payload does not decode to a numeric `exp`.
DateTime? _jwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
    final exp = payload['exp'];
    if (exp is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  } catch (_) {
    return null;
  }
}
