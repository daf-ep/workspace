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

import 'package:args/command_runner.dart';

import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/globals.dart' as globals;
import 'src/runner/injectable_command.dart';

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
Future<int> run(List<String> args, List<InjectableCommand> Function() commands, {Map<Type, Generator>? overrides}) {
  return AppContext.current.run<int>(
    name: 'injectable',
    overrides: overrides,
    body: () async {
      final runner = CommandRunner<int>('injectable', 'Sync the rules corpus into a project and manage its context.');
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
