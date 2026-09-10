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

import 'package:fiber_shell/fiber_shell.dart';

/// How long a git command that reaches out to `origin` gets before it counts
/// as unreachable.
///
/// A `dpw hook` call runs synchronously inside a Claude Code hook, which has
/// its own timeout: a push that hangs on a bad connection would otherwise
/// cost the caller its entire budget instead of failing cleanly within this
/// one, smaller than any hook's.
const Duration _networkTimeout = Duration(seconds: 10);

/// The author and committer identity dpw's own plumbing commits carry.
///
/// `commit-tree` refuses to build a commit at all when git has neither
/// `user.name` nor `user.email` configured anywhere, which a fresh checkout,
/// a CI runner included, often does not. dpw's commits are not the user's
/// own, so they carry this identity instead of depending on one.
const Map<String, String> commitIdentityEnv = {
  'GIT_AUTHOR_NAME': 'dpw',
  'GIT_AUTHOR_EMAIL': 'dpw@localhost',
  'GIT_COMMITTER_NAME': 'dpw',
  'GIT_COMMITTER_EMAIL': 'dpw@localhost',
};

/// Runs [command], the way [GitCmd.output] does, except a call that reaches
/// `origin` and does not answer within [_networkTimeout] counts as failed
/// rather than left hanging.
Future<ShellResult> runGit(GitCmd command, {String? input, Map<String, String>? env}) async {
  try {
    return await command.output(input: input, env: env).timeout(_networkTimeout);
  } on TimeoutException {
    return ShellResult(
      command: command.line,
      exitCode: 1,
      bytes: const [],
      errorBytes: const [],
      duration: _networkTimeout,
    );
  }
}

/// The commit [branch] currently points to on `origin`, or null when
/// `origin` carries no such branch yet, or could not be reached.
Future<String?> remoteBranchTip(Directory projectRoot, String branch) async {
  final result = await runGit(Git.repo(projectRoot.path).lsRemote().token('origin').token('refs/heads/$branch'));
  if (result.failed || result.text.trim().isEmpty) return null;
  return result.text.trim().split(RegExp(r'\s+')).first;
}
