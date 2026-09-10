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

import 'dart:async';
import 'dart:io';

import 'package:cli/src/rules/database.dart';
import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'support/fake_git_repo.dart';

void main() {
  // sqlite3 ships as a native asset, which `dart compile exe` cannot embed:
  // only `dart build cli` resolves the build hook that bundles libsqlite3
  // beside the executable, in a `bin/` and `lib/` bundle rather than a single
  // file.
  late Directory bundle;
  late Directory project;
  late String executablePath;

  setUpAll(() async {
    bundle = Directory.systemTemp.createTempSync('dpw_bundle_');

    final build = await Process.run(Platform.resolvedExecutable, [
      'build',
      'cli',
      '-o',
      bundle.path,
    ], workingDirectory: Directory.current.path);
    if (build.exitCode != 0) {
      fail('dart build cli failed:\n${build.stdout}\n${build.stderr}');
    }

    executablePath = p.join(bundle.path, 'bundle', 'bin', 'dpw');
    await _copyDirectory(
      Directory(p.join(Directory.current.path, '..', 'rules')),
      Directory(p.join(bundle.path, 'bundle', 'bin', 'rules')),
    );
  });

  tearDownAll(() => bundle.deleteSync(recursive: true));

  setUp(() async {
    project = Directory.systemTemp.createTempSync('dpw_project_');
    await initFakeGitRepo(project, remote: 'git@github.com:dpw-tests/standalone-e2e.git');
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('finds its own rules once compiled, without a source checkout nearby', () async {
    final rulesDatabasePath = p.join(project.path, 'rules.sqlite3');

    final result = await Process.run(
      executablePath,
      ['init'],
      workingDirectory: project.path,
      environment: {'DPW_RULES_DATABASE': rulesDatabasePath, 'DPW_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000'},
    );

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, contains('this project is github.com/dpw-tests/standalone-e2e'));
    expect(await readRule(databasePath: rulesDatabasePath, name: 'rules', type: 'rules'), isNotNull);
    expect(File(p.join(project.path, '.claude', 'dpw', 'push.md')).existsSync(), isTrue);
  });

  test('the bundled native sqlite3 library loads and records a decision', () async {
    final databasePath = p.join(project.path, 'decisions.sqlite3');

    final client = MCPClient(Implementation(name: 'standalone_binary_e2e_test', version: '0.0.1'));
    final process = await Process.start(
      executablePath,
      ['mcp'],
      workingDirectory: project.path,
      environment: {'DPW_DECISIONS_DATABASE': databasePath, 'DPW_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000'},
    );
    addTearDown(process.kill);

    final server = client.connectServer(stdioChannel(input: process.stdout, output: process.stdin));
    await server.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: client.capabilities,
        clientInfo: client.implementation,
      ),
    );
    server.notifyInitialized();

    final result = await server.callTool(
      CallToolRequest(
        name: 'record_decision',
        arguments: {
          'decided': 'x',
          'why': 'y',
          'implies': 'z',
          'verified': 'this end-to-end test, against the bundled executable',
        },
      ),
    );
    expect(result.isError, isNot(true));
    await client.shutdown();

    final db = sqlite3.open(databasePath);
    addTearDown(db.close);
    expect(db.select('SELECT decided FROM decisions'), hasLength(1));
  });
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  destination.createSync(recursive: true);
  for (final entity in source.listSync()) {
    final name = p.basename(entity.path);
    final targetPath = p.join(destination.path, name);
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    }
  }
}
