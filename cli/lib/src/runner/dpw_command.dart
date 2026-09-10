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

import 'package:args/command_runner.dart';

import '../globals.dart' as globals;
import '../rules/update_check.dart';

/// How a command ended.
enum ExitStatus {
  /// The command did what it was asked.
  success,

  /// The command could not do what it was asked.
  fail,
}

/// What a command answers when it returns.
class DpwCommandResult {
  /// Ends the command on [exitStatus].
  const DpwCommandResult(this.exitStatus);

  /// Ends the command on [ExitStatus.success].
  const DpwCommandResult.success() : this(ExitStatus.success);

  /// Ends the command on [ExitStatus.fail].
  const DpwCommandResult.fail() : this(ExitStatus.fail);

  /// How the command ended.
  final ExitStatus exitStatus;
}

/// The base every dpw command extends.
///
/// A subclass writes [runCommand] and returns the [DpwCommandResult] it ended
/// on, instead of a bare integer: what a command can answer grows here, once,
/// rather than at every call site that reads an exit code.
abstract class DpwCommand extends Command<int> {
  /// Opens a context for this command and runs it.
  ///
  /// The child context is what lets a test override this command's logger, or
  /// any other dependency, without changing what [runCommand] itself does.
  @override
  Future<int> run() {
    return globals.context.run<int>(
      name: name,
      body: () async {
        final DpwCommandResult result = await runCommand();
        await _checkForRemoteUpdates();
        return result.exitStatus == ExitStatus.success ? 0 : 1;
      },
    );
  }

  /// Runs the best-effort remote update check, swallowing whatever it
  /// throws.
  ///
  /// A network failure already comes back as a plain "no update" from
  /// [maybeCheckForRemoteUpdates] itself. What lands here instead is a local
  /// problem, a corrupt database file or a permission error on
  /// `.claude/dpw/`, and this command already did its own job by the time
  /// that check runs: it should not fail because of it.
  Future<void> _checkForRemoteUpdates() async {
    try {
      final updated = await maybeCheckForRemoteUpdates(
        rulesDatabasePath: globals.rulesDatabasePath,
        projectRoot: globals.projectRoot,
        interval: globals.remoteUpdateCheckInterval,
      );
      if (updated) {
        globals.logger.printStatus('dpw: refreshed the shared rules corpus from daf-ep/workspace');
      }
    } catch (_) {
      return;
    }
  }

  /// What this command does, once it is reached.
  Future<DpwCommandResult> runCommand();
}
