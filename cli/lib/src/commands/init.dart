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

import 'package:path/path.dart' as p;

import '../base/common.dart';
import '../globals.dart' as globals;
import '../project_id.dart';
import '../rules_sync.dart';
import '../runner/dpw_command.dart';

/// Creates `.claude/rules` in the current directory and assigns this
/// project its id.
class InitCommand extends DpwCommand {
  @override
  final name = 'init';

  @override
  final description = 'Sync .claude/rules from this checkout and assign the project an id.';

  @override
  Future<DpwCommandResult> runCommand() async {
    final rulesSource = globals.rulesSource;
    if (rulesSource == null) {
      throwToolExit('dpw: no rules directory found next to this tool');
    }

    final cwd = Directory.current.path;
    final rulesDest = Directory(p.join(cwd, '.claude', 'rules'));
    syncRules(source: rulesSource, destination: rulesDest);
    globals.logger.printStatus('dpw: rules synced into ${rulesDest.path}');

    final idFile = File(p.join(cwd, '.claude', 'ID'));
    final id = ensureProjectId(idFile);
    if (id.created) {
      globals.logger.printStatus('dpw: assigned this project id ${id.id}');
    } else {
      globals.logger.printStatus('dpw: this project already has id ${id.id}');
    }

    return const DpwCommandResult.success();
  }
}
