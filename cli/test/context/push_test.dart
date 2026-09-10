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

import 'package:cli/src/context/push.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';

void main() {
  late Directory workspace;
  late Directory project;
  late Directory remote;
  late File databaseFile;

  setUp(() async {
    workspace = Directory.systemTemp.createTempSync('dpw_context_push_');
    project = Directory(p.join(workspace.path, 'project'))..createSync();
    remote = await createBareRemote(workspace);
    await initFakeGitRepo(project, remote: remote.path);
    databaseFile = File(p.join(project.path, 'context'))..writeAsStringSync('first version');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  test('does nothing when the database file does not exist yet', () async {
    final missing = File(p.join(project.path, 'missing'));

    final pushed = await pushContextDatabase(
      projectRoot: project,
      branch: 'dpw-context',
      databaseFile: missing,
      fileName: 'context',
    );

    expect(pushed, isFalse);
  });

  test('pushes the file to origin under the given branch and name', () async {
    final pushed = await pushContextDatabase(
      projectRoot: project,
      branch: 'dpw-context',
      databaseFile: databaseFile,
      fileName: 'context',
    );

    expect(pushed, isTrue);
    expect(await _checkedOutContent(workspace, remote, 'dpw-context', 'context'), 'first version');
  });

  test('never touches this project\'s own working tree or index', () async {
    await pushContextDatabase(
      projectRoot: project,
      branch: 'dpw-context',
      databaseFile: databaseFile,
      fileName: 'context',
    );

    final status = await Process.run('git', ['-C', project.path, 'status', '--porcelain', '--branch']);
    expect((status.stdout as String), contains('No commits yet'));
  });

  test('a second push builds on the first instead of replacing its history', () async {
    await pushContextDatabase(
      projectRoot: project,
      branch: 'dpw-context',
      databaseFile: databaseFile,
      fileName: 'context',
    );

    databaseFile.writeAsStringSync('second version');
    await pushContextDatabase(
      projectRoot: project,
      branch: 'dpw-context',
      databaseFile: databaseFile,
      fileName: 'context',
    );

    final log = await Process.run('git', ['-C', remote.path, 'log', '--oneline', 'dpw-context']);
    expect((log.stdout as String).trim().split('\n'), hasLength(2));
    expect(await _checkedOutContent(workspace, remote, 'dpw-context', 'context'), 'second version');
  });
}

Future<String> _checkedOutContent(Directory workspace, Directory remote, String branch, String fileName) async {
  final clone = Directory(p.join(workspace.path, 'clone_${DateTime.now().microsecondsSinceEpoch}'));
  final result = await Process.run('git', ['clone', '--quiet', '--branch', branch, remote.path, clone.path]);
  if (result.exitCode != 0) {
    throw StateError('git clone failed:\n${result.stdout}\n${result.stderr}');
  }
  return File(p.join(clone.path, fileName)).readAsStringSync();
}
