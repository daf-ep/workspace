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

import 'dart:io';

import 'package:args/command_runner.dart';

import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/globals.dart' as globals;
import 'src/runner/dpw_command.dart';

/// The status a command called the wrong way leaves with, as `sysexits.h` names it.
const int kExitCodeUsage = 64;

/// Runs [args] against the commands [commands] builds, and returns the exit status.
///
/// [commands] is a callback and not a list because a command is built inside
/// the context, where an override from [overrides] already answers.
///
/// This is where the process learns how it ends, and the only place that
/// knows: a [ToolExit] carries its own status, a command called wrong answers
/// [kExitCodeUsage], anything a command returns otherwise passes through
/// as is.
///
/// [overrides] replaces entries of the context, which is how a test runs a
/// command against its own logger or rules source.
Future<int> run(List<String> args, List<DpwCommand> Function() commands, {Map<Type, Generator>? overrides}) {
  return AppContext.current.run<int>(
    name: 'dpw',
    overrides: overrides,
    body: () async {
      final runner = CommandRunner<int>('dpw', 'Sync the rules corpus into a project and manage its context.');
      commands().forEach(runner.addCommand);

      try {
        return await runner.run(args) ?? 0;
      } on ToolExit catch (error) {
        if (error.message case final String message) globals.logger.printError(message);
        return error.exitCode;
      } on UsageException catch (error) {
        stderr.writeln(error);
        return kExitCodeUsage;
      }
    },
  );
}
