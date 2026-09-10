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

import 'git_network.dart';

/// Commits [databaseFile] as [fileName] on [branch] and pushes it to
/// `origin`, without ever touching this project's working tree or index:
/// every step is a plumbing command building objects directly, the way a
/// bot deploys to `gh-pages` without checking it out.
///
/// Parents the new commit on whatever [branch] currently points to on
/// `origin`, read fresh right before committing, so a push a teammate made
/// in between is not clobbered; git itself still refuses the push as a
/// non-fast-forward on the rare race where both land at the same instant.
///
/// Returns whether the push succeeded. Never throws: a failure here, offline
/// or a losing race, is left for the next attempt rather than reported as an
/// error.
Future<bool> pushContextDatabase({
  required Directory projectRoot,
  required String branch,
  required File databaseFile,
  required String fileName,
}) async {
  if (!databaseFile.existsSync()) return false;
  final path = projectRoot.path;

  final blob = await Git.repo(path).hashObject().token('-w').token(databaseFile.path).output();
  if (blob.failed) return false;

  final tree = await Git.repo(path).mktree().output(input: '100644 blob ${blob.text.trim()}\t$fileName\n');
  if (tree.failed) return false;

  final parent = await remoteBranchTip(projectRoot, branch);
  final commitCommand = Git.repo(path).commitTree().token(tree.text.trim());
  if (parent != null) commitCommand.token('-p').token(parent);
  final commit = await commitCommand.token('-m').token('dpw: context update').output(env: commitIdentityEnv);
  if (commit.failed) return false;

  final pushed = await runGit(Git.repo(path).push().token('origin').token('${commit.text.trim()}:refs/heads/$branch'));
  return pushed.success;
}
