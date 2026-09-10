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
import '../mcp_config.dart';
import '../rules/database.dart';
import '../rules/sync.dart';
import '../runner/dpw_command.dart';

/// Syncs the shared rules database from this checkout, ensures this
/// project's customization stubs exist, and declares dpw's MCP server in
/// `.mcp.json`.
class InitCommand extends DpwCommand {
  @override
  final name = 'init';

  @override
  final description = 'Sync the shared rules database from this checkout and declare the mcp server.';

  @override
  Future<DpwCommandResult> runCommand() async {
    final cwd = globals.projectRoot;
    globals.logger.printStatus('dpw: this project is ${await globals.projectId}');

    final rulesSource = globals.rulesSource;
    if (rulesSource == null) {
      throwToolExit('dpw: no rules directory found next to this tool');
    }

    await syncRulesDatabase(databasePath: globals.rulesDatabasePath, contents: collectRuleContents(rulesSource));
    globals.logger.printStatus('dpw: shared rules synced into ${globals.rulesDatabasePath}');

    final customizationDest = Directory(p.join(cwd.path, '.claude', 'rules', 'customization'));
    syncCustomization(source: Directory(p.join(rulesSource.path, 'customization')), destination: customizationDest);
    globals.logger.printStatus('dpw: customization stubs ensured in ${customizationDest.path}');

    ensureMcpServerDeclared(cwd);
    globals.logger.printStatus('dpw: declared the mcp server in .mcp.json');

    return const DpwCommandResult.success();
  }
}
