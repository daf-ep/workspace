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

import 'package:cli/src/base/context.dart';
import 'package:cli/src/base/logger.dart';
import 'package:cli/src/commands/init.dart';
import 'package:cli/src/globals.dart';
import 'package:cli/src/rules/database.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('logs through the injected logger instead of a real stream', () async {
    final rulesSource = Directory(p.join(Directory.current.path, '..', 'rules'));
    final project = Directory.systemTemp.createTempSync('dpw_init_command_');
    final rulesDatabaseDir = Directory.systemTemp.createTempSync('dpw_init_command_rules_db_');
    final rulesDatabasePath = p.join(rulesDatabaseDir.path, 'rules.sqlite3');
    addTearDown(() => project.deleteSync(recursive: true));
    addTearDown(() => rulesDatabaseDir.deleteSync(recursive: true));

    final buffer = BufferLogger();

    final exitCode = await AppContext.current.run<int>(
      body: () => InitCommand().run(),
      overrides: <Type, Generator>{
        Logger: () => buffer,
        RulesSource: () => RulesSource(rulesSource),
        ProjectRoot: () => ProjectRoot(project),
        GitProjectId: () => const GitProjectId('github.com/dpw-tests/init-command-test'),
        RulesDatabasePath: () => RulesDatabasePath(rulesDatabasePath),
      },
    );

    expect(exitCode, 0);
    expect(buffer.hadErrorOutput, isFalse);
    expect(buffer.statusText, contains('this project is github.com/dpw-tests/init-command-test'));
    expect(buffer.statusText, contains('shared rules synced into'));
    expect(buffer.statusText, contains('customization stubs ensured'));
    expect(buffer.statusText, contains('declared the mcp server'));
    expect(await readRule(databasePath: rulesDatabasePath, name: 'rules', type: 'rules'), isNotNull);
    expect(File(p.join(project.path, '.claude', 'rules', 'customization', 'push.md')).existsSync(), isTrue);
    expect(File(p.join(project.path, '.mcp.json')).existsSync(), isTrue);
  });
}
