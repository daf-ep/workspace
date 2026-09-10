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

import 'package:cli/src/context/orphan_branch.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';

void main() {
  late Directory workspace;
  late Directory project;
  late Directory remote;

  setUp(() async {
    workspace = Directory.systemTemp.createTempSync('dpw_orphan_branch_');
    project = Directory(p.join(workspace.path, 'project'))..createSync();
    remote = await createBareRemote(workspace);
    await initFakeGitRepo(project, remote: remote.path);
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  test('creates the branch on origin when it does not exist yet', () async {
    await ensureOrphanBranch(projectRoot: project, branch: 'dpw-context');

    final tip = await _remoteTip(remote, 'dpw-context');
    expect(tip, isNotNull);
  });

  test('the created branch has no parent commit, a true orphan', () async {
    await ensureOrphanBranch(projectRoot: project, branch: 'dpw-context');

    final tip = await _remoteTip(remote, 'dpw-context');
    final parents = await Process.run('git', ['-C', remote.path, 'log', '--format=%P', '-1', tip!]);

    expect((parents.stdout as String).trim(), isEmpty);
  });

  test('does nothing when the branch already exists on origin', () async {
    await ensureOrphanBranch(projectRoot: project, branch: 'dpw-context');
    final firstTip = await _remoteTip(remote, 'dpw-context');

    await ensureOrphanBranch(projectRoot: project, branch: 'dpw-context');
    final secondTip = await _remoteTip(remote, 'dpw-context');

    expect(secondTip, firstTip);
  });
}

Future<String?> _remoteTip(Directory remote, String branch) async {
  final result = await Process.run('git', ['-C', remote.path, 'rev-parse', '--verify', '--quiet', branch]);
  final sha = (result.stdout as String).trim();
  return sha.isEmpty ? null : sha;
}
