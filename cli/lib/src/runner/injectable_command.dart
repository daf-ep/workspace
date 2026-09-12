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

import 'package:args/command_runner.dart';

import '../base/common.dart';
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
class InjectableCommandResult {
  /// Ends the command on [exitStatus].
  const InjectableCommandResult(this.exitStatus);

  /// Ends the command on [ExitStatus.success].
  const InjectableCommandResult.success() : this(ExitStatus.success);

  /// Ends the command on [ExitStatus.fail].
  const InjectableCommandResult.fail() : this(ExitStatus.fail);

  /// How the command ended.
  final ExitStatus exitStatus;
}

/// The base every injectable command extends.
///
/// A subclass writes [runCommand] and returns the [InjectableCommandResult] it ended
/// on, instead of a bare integer: what a command can answer grows here, once,
/// rather than at every call site that reads an exit code.
abstract class InjectableCommand extends Command<int> {
  /// Opens a context for this command and runs it.
  ///
  /// The child context is what lets a test override this command's logger, or
  /// any other dependency, without changing what [runCommand] itself does.
  @override
  Future<int> run() {
    return globals.context.run<int>(
      name: name,
      body: () async {
        if (requiresAuthentication && globals.storedSession == null) {
          throwToolExit('injectable: not logged in. Run `injectable login` first.');
        }

        final InjectableCommandResult result = await runCommand();
        await _checkForRemoteUpdates();
        return result.exitStatus == ExitStatus.success ? 0 : 1;
      },
    );
  }

  /// Whether this command refuses to run at all without a stored session.
  ///
  /// True for every command but `login` and `logout`, which have to work
  /// with no session yet to be the way one is obtained or cleared, and
  /// `bridge`: that command is invoked by Claude Code itself, never directly
  /// by whoever is or isn't logged in, and its own contract is to never
  /// fail regardless of the reason, so it decides for itself, inside its
  /// own guarded body, what a missing session means.
  bool get requiresAuthentication => true;

  /// Runs the best-effort remote update check, swallowing whatever it
  /// throws.
  ///
  /// A network failure already comes back as a plain "no update" from
  /// [maybeCheckForRemoteUpdates] itself. What lands here instead is a local
  /// problem, a corrupt database file or a permission error on
  /// `.claude/injectable/`, and this command already did its own job by the time
  /// that check runs: it should not fail because of it.
  Future<void> _checkForRemoteUpdates() async {
    try {
      final updated = await maybeCheckForRemoteUpdates(
        rulesStoreRoot: globals.rulesStoreRoot,
        projectRoot: globals.projectRoot,
        interval: globals.remoteUpdateCheckInterval,
      );
      if (updated) {
        globals.logger.printStatus('injectable: refreshed the shared rules corpus from daf-ep/injectable');
      }
    } catch (_) {
      return;
    }
  }

  /// What this command does, once it is reached.
  Future<InjectableCommandResult> runCommand();
}
