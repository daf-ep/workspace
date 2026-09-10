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

import 'package:cli/src/rules/database.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';

void main() {
  test('running init syncs the shared rules database and .mcp.json for real, in a real git repo', () async {
    final project = Directory.systemTemp.createTempSync('dafep_e2e_');
    final rulesDatabaseDir = Directory.systemTemp.createTempSync('dafep_e2e_rules_db_');
    addTearDown(() => project.deleteSync(recursive: true));
    addTearDown(() => rulesDatabaseDir.deleteSync(recursive: true));
    await initFakeGitRepo(project, remote: 'git@github.com:dpw-tests/init-e2e.git');

    final binPath = p.join(Directory.current.path, 'bin', 'dpw.dart');
    final rulesDatabasePath = p.join(rulesDatabaseDir.path, 'rules.sqlite3');

    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', binPath, 'init'],
      workingDirectory: project.path,
      environment: {'DPW_RULES_DATABASE': rulesDatabasePath},
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('this project is github.com/dpw-tests/init-e2e'));
    expect(await readRule(databasePath: rulesDatabasePath, name: 'rules', type: 'rules'), isNotNull);
    expect(File(p.join(project.path, '.claude', 'dpw', 'push.md')).existsSync(), isTrue);

    final mcpConfig = jsonDecode(File(p.join(project.path, '.mcp.json')).readAsStringSync()) as Map<String, dynamic>;
    final servers = mcpConfig['mcpServers'] as Map<String, dynamic>;
    expect(servers['dpw-decisions'], {
      'command': 'dpw',
      'args': ['mcp'],
    });
  });

  test('refuses to run outside a git repository', () async {
    final project = Directory.systemTemp.createTempSync('dafep_e2e_no_git_');
    addTearDown(() => project.deleteSync(recursive: true));

    final binPath = p.join(Directory.current.path, 'bin', 'dpw.dart');

    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      binPath,
      'init',
    ], workingDirectory: project.path);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('not a git repository'));
  });

  test('refuses a remote hosted anywhere but GitHub or GitLab', () async {
    final project = Directory.systemTemp.createTempSync('dafep_e2e_wrong_host_');
    addTearDown(() => project.deleteSync(recursive: true));
    await initFakeGitRepo(project, remote: 'git@bitbucket.org:someone/somewhere.git');

    final binPath = p.join(Directory.current.path, 'bin', 'dpw.dart');

    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      binPath,
      'init',
    ], workingDirectory: project.path);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('only GitHub and GitLab'));
  });
}
