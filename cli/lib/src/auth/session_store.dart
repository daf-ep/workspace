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

import 'git_host.dart';

/// The dpw session `dpw login` obtained, held on this machine until
/// `dpw logout` or a fresh `dpw login` replaces it.
class StoredSession {
  /// Wraps an already-minted [token], identifying [login] on [host].
  const StoredSession({required this.token, required this.host, required this.login});

  /// The dpw session token every authenticated request carries.
  final String token;

  /// Which host [login] was linked through.
  final GitHost host;

  /// The account's handle on [host], as of the last login.
  final String login;

  /// This session, ready for [SessionStore] to write to disk.
  Map<String, dynamic> toJson() => {'token': token, 'host': host.name, 'login': login};

  /// The session [json] describes, or null when it is missing a field or
  /// names a host [GitHost.parse] does not recognise: either way, this is
  /// not a session `dpw` can use, and is treated the same as none at all.
  static StoredSession? fromJson(Map<String, dynamic> json) {
    final host = GitHost.parse(json['host'] as String?);
    final token = json['token'] as String?;
    final login = json['login'] as String?;
    if (host == null || token == null || login == null) return null;
    return StoredSession(token: token, host: host, login: login);
  }
}

/// Reads and writes the [StoredSession] at [path].
///
/// A missing or unreadable file means "not logged in", the ordinary state
/// for a machine that never ran `dpw login`, so [read] returns null rather
/// than throwing for either.
class SessionStore {
  /// Persists sessions at [path].
  const SessionStore(this.path);

  /// Where this store keeps its one session.
  final String path;

  /// The session stored at [path], or null when there is none, or when
  /// what is there cannot be read as one.
  StoredSession? read() {
    final file = File(path);
    if (!file.existsSync()) return null;

    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return StoredSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Replaces whatever is at [path] with [session].
  ///
  /// Restricted to this account's own read and write on every platform but
  /// Windows, whose ACL model `chmod` does not speak for: the token in
  /// here is as sensitive as a password, and a shared machine should not
  /// leave it world-readable even for the moment before this returns.
  void save(StoredSession session) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(session.toJson()));
    if (!Platform.isWindows) Process.runSync('chmod', ['600', path]);
  }

  /// Removes whatever session is stored at [path], if any.
  void clear() {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
}
