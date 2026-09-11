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

import 'dart:io';

import '../runner/injectable_command.dart';

/// Records one Claude Code hook event, for later processing.
///
/// This is what `.claude/settings.json` calls for `SessionStart`,
/// `UserPromptSubmit` and `Stop`, one event name per registration. Never
/// fails: a hook Claude Code is waiting on has no use for an error from a
/// capture mechanism that is not part of what the user asked it to do.
///
/// Capture is being rebuilt against injectable's backend, sealed per-event
/// encryption instead of a symmetric key shared by hand, no push into this
/// project's own git history. Nothing is recorded anywhere until that
/// lands: this drains its stdin payload, so Claude Code never blocks
/// writing one, and otherwise does nothing with it.
class HookCommand extends InjectableCommand {
  @override
  final name = 'hook';

  @override
  final description = "Records one Claude Code hook event's raw payload, for later processing.";

  @override
  bool get requiresAuthentication => false;

  @override
  Future<InjectableCommandResult> runCommand() async {
    await stdin.drain<void>();
    return const InjectableCommandResult.success();
  }
}
