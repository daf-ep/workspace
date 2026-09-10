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

import 'package:fiber_shell/fiber_shell.dart';

import '../base/common.dart';
import 'git_network.dart';

/// The empty tree every git repository already has, by its well-known
/// object id: hashing zero entries always gives the same sha.
const String _emptyTreeSha = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';

/// Ensures [branch] exists on `origin`, as an orphan: a root commit with no
/// parent, so it shares no history with any other branch, the way
/// `gh-pages` shares none with `main`.
///
/// Does nothing when the branch already exists on `origin`, whether this
/// project or a teammate's created it: two independent orphan roots under
/// the same name would never share history, so every future push would
/// fail as a non-fast-forward.
Future<void> ensureOrphanBranch({required Directory projectRoot, required String branch}) async {
  if (await remoteBranchTip(projectRoot, branch) != null) return;

  final root = await runGit(
    Git.repo(projectRoot.path).commitTree().token(_emptyTreeSha).token('-m').token('dpw: start the $branch branch'),
  );
  if (root.failed) throwToolExit('dpw: could not create the $branch branch.\n${root.stderr}');

  final pushed = await runGit(
    Git.repo(projectRoot.path).push().token('origin').token('${root.text.trim()}:refs/heads/$branch'),
  );
  if (pushed.failed) throwToolExit('dpw: could not push the $branch branch.\n${pushed.stderr}');
}
