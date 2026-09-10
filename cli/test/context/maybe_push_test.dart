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

import 'package:cli/src/context/database.dart';
import 'package:cli/src/context/maybe_push.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';

void main() {
  late Directory workspace;
  late Directory project;
  late Directory remote;
  late String databasePath;

  setUp(() async {
    workspace = Directory.systemTemp.createTempSync('dpw_maybe_push_');
    project = Directory(p.join(workspace.path, 'project'))..createSync();
    remote = await createBareRemote(workspace);
    await initFakeGitRepo(project, remote: remote.path);
    databasePath = p.join(project.path, 'context');
    recordRawEvent(databasePath: databasePath, hookEvent: 'stop', payload: '{}');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  test('is not due when the interval since the last push has not passed', () async {
    recordPushedAt(databasePath: databasePath, time: DateTime.now());

    final pushed = await maybePushContext(
      projectRoot: project,
      branch: 'dpw-context',
      databasePath: databasePath,
      fileName: 'context',
      interval: const Duration(minutes: 5),
    );

    expect(pushed, isFalse);
  });

  test('a database that was never pushed is due under the ordinary interval', () async {
    final pushed = await maybePushContext(
      projectRoot: project,
      branch: 'dpw-context',
      databasePath: databasePath,
      fileName: 'context',
      interval: const Duration(minutes: 5),
    );

    expect(pushed, isTrue);
  });

  test('an interval longer than the time since the epoch suppresses even a never-pushed database', () async {
    final pushed = await maybePushContext(
      projectRoot: project,
      branch: 'dpw-context',
      databasePath: databasePath,
      fileName: 'context',
      interval: const Duration(days: 365 * 100),
    );

    expect(pushed, isFalse);
  });

  test('records the push attempt time even though the push failed', () async {
    final unreachableRemote = Directory(p.join(workspace.path, 'does_not_exist'));
    final orphanProject = Directory(p.join(workspace.path, 'orphan_project'))..createSync();
    await initFakeGitRepo(orphanProject, remote: unreachableRemote.path);
    final orphanDatabasePath = p.join(orphanProject.path, 'context');
    recordRawEvent(databasePath: orphanDatabasePath, hookEvent: 'stop', payload: '{}');

    final pushed = await maybePushContext(
      projectRoot: orphanProject,
      branch: 'dpw-context',
      databasePath: orphanDatabasePath,
      fileName: 'context',
      interval: Duration.zero,
    );

    expect(pushed, isFalse);
    expect(lastPushedAt(databasePath: orphanDatabasePath), isNotNull);
  });
}
