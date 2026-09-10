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

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';

void main() {
  late Directory workspace;
  late Directory project;
  late String binPath;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('dpw_hook_command_e2e_');
    project = Directory(p.join(workspace.path, 'project'))..createSync();
    binPath = p.join(Directory.current.path, 'bin', 'dpw.dart');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  test('records the payload it receives on stdin, under the event name given', () async {
    await initFakeGitRepo(project);

    final exitCode = await _runHook(
      binPath,
      project,
      event: 'stop',
      payload: '{"last_assistant_message":"done"}',
      environment: {'DPW_CONTEXT_PUSH_INTERVAL_SECONDS': '315360000000'},
    );

    expect(exitCode, 0);

    final db = sqlite3.open(p.join(project.path, '.claude', 'context'));
    addTearDown(db.close);
    final rows = db.select('SELECT hook_event, payload FROM raw_events');

    expect(rows, hasLength(1));
    expect(rows.first['hook_event'], 'stop');
    expect(rows.first['payload'], '{"last_assistant_message":"done"}');
  });

  test('does nothing, successfully, when called with no event name', () async {
    await initFakeGitRepo(project);

    final exitCode = await _runHook(binPath, project, event: null, payload: '{}');

    expect(exitCode, 0);
    expect(File(p.join(project.path, '.claude', 'context')).existsSync(), isFalse);
  });

  test('pushes the context database to its branch when a push is due', () async {
    final remote = await createBareRemote(workspace);
    await initFakeGitRepo(project, remote: remote.path);

    final exitCode = await _runHook(
      binPath,
      project,
      event: 'session-start',
      payload: '{"session_start_reason":"startup"}',
      environment: {'DPW_CONTEXT_PUSH_INTERVAL_SECONDS': '0'},
    );

    expect(exitCode, 0);

    final tip = await Process.run('git', ['-C', remote.path, 'rev-parse', '--verify', '--quiet', 'dpw-context']);
    expect((tip.stdout as String).trim(), isNotEmpty);
  });
}

Future<int> _runHook(
  String binPath,
  Directory project, {
  required String? event,
  required String payload,
  Map<String, String> environment = const {},
}) async {
  final process = await Process.start(
    Platform.resolvedExecutable,
    ['run', binPath, 'hook', ?event],
    workingDirectory: project.path,
    environment: {'DPW_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000', ...environment},
  );

  process.stdin.write(payload);
  await process.stdin.close();

  final stderrOutput = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;
  if (exitCode != 0) fail('dpw hook exited $exitCode:\n$stderrOutput');
  return exitCode;
}
