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

import '../context/constants.dart';
import '../context/database.dart';
import '../context/maybe_push.dart';
import '../globals.dart' as globals;
import '../runner/dpw_command.dart';

/// Records one Claude Code hook's raw stdin payload, and pushes the context
/// database to its orphan branch when a push is due.
///
/// This is what `.claude/settings.json` calls for `SessionStart`,
/// `UserPromptSubmit` and `Stop`, one event name per registration. Never
/// fails: a hook Claude Code is waiting on has no use for an error from a
/// capture mechanism that is not part of what the user asked it to do.
///
/// Does nothing at all when `DPW_CONTEXT_KEY` is not set: the database is
/// encrypted, and this never writes a single byte of it unencrypted, so
/// with no key there is nothing safe for it to do.
class HookCommand extends DpwCommand {
  @override
  final name = 'hook';

  @override
  final description = "Records one Claude Code hook event's raw payload, for later processing.";

  @override
  Future<DpwCommandResult> runCommand() async {
    await _captureAndMaybePush();
    return const DpwCommandResult.success();
  }

  Future<void> _captureAndMaybePush() async {
    try {
      final keyBytes = globals.contextEncryptionKeyBytes;
      if (keyBytes == null) return;

      final arguments = argResults?.rest ?? const <String>[];
      if (arguments.isEmpty) return;
      final event = arguments.first;

      final payload = await stdin.transform(utf8.decoder).join();
      final databasePath = globals.contextDatabasePath;
      await recordRawEvent(databasePath: databasePath, keyBytes: keyBytes, hookEvent: event, payload: payload);

      await maybePushContext(
        projectRoot: globals.projectRoot,
        branch: contextBranch,
        databasePath: databasePath,
        keyBytes: keyBytes,
        fileName: contextFileName,
        interval: globals.contextPushInterval,
      );
    } catch (_) {
      return;
    }
  }
}
