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

library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'base/common.dart';
import 'base/context.dart';
import 'base/logger.dart';
import 'context/encryption.dart';
import 'git_identity.dart';
import 'rules/sync.dart';

/// The context the current zone carries.
AppContext get context => AppContext.current;

Logger? _loggerInstance;

/// Everything this run prints.
Logger get logger => context.get<Logger>() ?? (_loggerInstance ??= StdoutLogger());

/// Where this run's rules directory is, found once and read from the context after that.
///
/// Wrapped rather than looked up through the raw [Directory] type, so a test
/// overriding it never risks colliding with an unrelated one a future
/// override might register.
class RulesSource {
  /// Wraps [directory], the answer [rulesSource] should give for this run.
  const RulesSource(this.directory);

  /// The rules directory this run reads from, or null when none was found.
  final Directory? directory;
}

/// The rules directory this run syncs from, or null when none was found.
Directory? get rulesSource => (context.get<RulesSource>() ?? RulesSource(findRulesSource())).directory;

/// The project this run works on.
///
/// Wrapped rather than looked up through the raw [Directory] type, so a test
/// overriding it never risks colliding with an unrelated one a future
/// override might register, and never has to mutate the real
/// [Directory.current] to point a command at a temporary project: doing that
/// is process-wide state, and races against any other test reading it at the
/// same time.
class ProjectRoot {
  /// Wraps [directory], the answer [projectRoot] should give for this run.
  const ProjectRoot(this.directory);

  /// The project this run works on.
  final Directory directory;
}

/// The project this run works on, [Directory.current] unless overridden.
Directory get projectRoot => (context.get<ProjectRoot>() ?? ProjectRoot(Directory.current)).directory;

/// This project's id, [gitProjectId] of [projectRoot] unless overridden.
///
/// Wrapped rather than looked up through the raw [String] type, so a test
/// overriding it never risks colliding with an unrelated one a future
/// override might register.
class GitProjectId {
  /// Wraps [value], the answer [projectId] should give for this run.
  const GitProjectId(this.value);

  /// The id this project's git remote gives it.
  final String value;
}

/// This project's id: `host/owner/repo`, read from its git remote.
Future<String> get projectId async {
  if (context.get<GitProjectId>() case final GitProjectId overridden) return overridden.value;
  return gitProjectId(projectRoot);
}

/// Where the decisions database this run reads and writes lives.
///
/// Wrapped rather than looked up through a raw [String], so a test overriding
/// it never risks colliding with an unrelated one a future override might
/// register.
class DecisionsDatabase {
  /// Wraps [path], the answer [decisionsDatabasePath] should give for this run.
  const DecisionsDatabase(this.path);

  /// The file this run's decisions database lives at.
  final String path;
}

/// The path to the decisions database this run reads and writes.
///
/// One database for every project, at a fixed place under the user's home,
/// so a decision made in one project stays queryable alongside every other
/// project's, keyed apart by the project id each row carries.
String get decisionsDatabasePath =>
    (context.get<DecisionsDatabase>() ?? DecisionsDatabase(_defaultDecisionsDatabasePath)).path;

String get _defaultDecisionsDatabasePath =>
    _dpwDataPath(envVariable: 'DPW_DECISIONS_DATABASE', filename: 'decisions.sqlite3');

/// Where the shared rules store this run reads and writes lives.
///
/// Wrapped rather than looked up through the raw [Directory] type, so a test
/// overriding it never risks colliding with an unrelated one a future
/// override might register.
class RulesStoreRoot {
  /// Wraps [directory], the answer [rulesStoreRoot] should give for this run.
  const RulesStoreRoot(this.directory);

  /// The directory this run's rules store lives at.
  final Directory directory;
}

/// The directory the rules store this run reads and writes lives at.
///
/// One store for every project on the machine, at a fixed place under the
/// user's home, so `dpw init` writes the corpus once and every project's
/// `dpw mcp` reads that same copy instead of one duplicated per project.
Directory get rulesStoreRoot =>
    (context.get<RulesStoreRoot>() ?? RulesStoreRoot(Directory(_defaultRulesStoreRootPath))).directory;

String get _defaultRulesStoreRootPath => _dpwDataPath(envVariable: 'DPW_RULES_DIR', filename: 'rules');

/// How long a remote update check, once made, holds off the next one.
///
/// Wrapped rather than looked up through a raw [Duration], so a test
/// overriding it never risks colliding with an unrelated one a future
/// override might register.
class RemoteUpdateCheckInterval {
  /// Wraps [duration], the answer [remoteUpdateCheckInterval] should give
  /// for this run.
  const RemoteUpdateCheckInterval(this.duration);

  /// The interval this run holds a check off for.
  final Duration duration;
}

/// How long this run holds a remote update check off for, a day unless
/// overridden.
Duration get remoteUpdateCheckInterval =>
    (context.get<RemoteUpdateCheckInterval>() ?? RemoteUpdateCheckInterval(_defaultRemoteUpdateCheckInterval)).duration;

Duration get _defaultRemoteUpdateCheckInterval =>
    _durationFromEnv(envVariable: 'DPW_UPDATE_CHECK_INTERVAL_SECONDS', defaultValue: const Duration(days: 1));

/// The path to this project's context database, holding the raw hook
/// payloads a Claude Code session generates while working here.
///
/// Local to the project rather than shared across every project the way
/// [rulesStoreRoot] and [decisionsDatabasePath] are: it belongs to this
/// project's own history on [contextBranch], not to this machine.
String get contextDatabasePath => p.join(projectRoot.path, '.claude', 'context');

/// How long a context push, once made, holds off the next one.
///
/// Wrapped rather than looked up through a raw [Duration], so a test
/// overriding it never risks colliding with an unrelated one a future
/// override might register.
class ContextPushInterval {
  /// Wraps [duration], the answer [contextPushInterval] should give for
  /// this run.
  const ContextPushInterval(this.duration);

  /// The interval this run holds a push off for.
  final Duration duration;
}

/// How long this run holds a context push off for, five minutes unless
/// overridden.
Duration get contextPushInterval =>
    (context.get<ContextPushInterval>() ?? ContextPushInterval(_defaultContextPushInterval)).duration;

Duration get _defaultContextPushInterval =>
    _durationFromEnv(envVariable: 'DPW_CONTEXT_PUSH_INTERVAL_SECONDS', defaultValue: const Duration(minutes: 5));

/// The key this project's context database is encrypted under.
///
/// Wrapped rather than looked up through a raw nullable `List<int>`, so a
/// test overriding it never risks colliding with an unrelated one a future
/// override might register.
class ContextEncryptionKey {
  /// Wraps [bytes], the answer [contextEncryptionKeyBytes] should give for
  /// this run.
  const ContextEncryptionKey(this.bytes);

  /// The key this run's context database is encrypted under, or null when
  /// no key is configured: context capture stays off until one is.
  final List<int>? bytes;
}

/// The key this run's context database is encrypted under, or null when
/// `DPW_CONTEXT_KEY` is not set.
List<int>? get contextEncryptionKeyBytes =>
    (context.get<ContextEncryptionKey>() ?? ContextEncryptionKey(_contextEncryptionKeyFromEnv)).bytes;

List<int>? get _contextEncryptionKeyFromEnv {
  final encoded = Platform.environment['DPW_CONTEXT_KEY'];
  if (encoded == null || encoded.isEmpty) return null;

  final List<int> bytes;
  try {
    bytes = base64Decode(encoded);
  } on FormatException {
    throwToolExit('dpw: DPW_CONTEXT_KEY is not valid base64.');
  }
  if (bytes.length != contextKeyLength) {
    throwToolExit('dpw: DPW_CONTEXT_KEY must decode to $contextKeyLength bytes, got ${bytes.length}.');
  }
  return bytes;
}

Duration _durationFromEnv({required String envVariable, required Duration defaultValue}) {
  if (Platform.environment[envVariable] case final String overridden when overridden.isNotEmpty) {
    return Duration(seconds: int.parse(overridden));
  }
  return defaultValue;
}

String _dpwDataPath({required String envVariable, required String filename}) {
  if (Platform.environment[envVariable] case final String overridden when overridden.isNotEmpty) {
    return overridden;
  }

  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) throwToolExit('dpw: could not find the home directory to store $filename in');
  return p.join(home, '.local', 'share', 'dpw', filename);
}
