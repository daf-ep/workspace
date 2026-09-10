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

import 'database.dart';
import 'push.dart';

/// Pushes the context database at [databasePath] to [branch] when
/// [interval] has passed since the last push. A database that has never
/// been pushed counts as pushed at the epoch, so it is always due.
///
/// Silent by design, the same way the rules corpus's own update check is:
/// a push that is not due yet, or that fails, offline or racing a teammate,
/// is the expected common case, not a failure to report. The last-pushed
/// time is written whether or not the push succeeds, so a machine offline
/// for a while pays the attempt at most once per [interval].
Future<bool> maybePushContext({
  required Directory projectRoot,
  required String branch,
  required String databasePath,
  required String fileName,
  required Duration interval,
}) async {
  final last = lastPushedAt(databasePath: databasePath) ?? DateTime.fromMillisecondsSinceEpoch(0);
  final now = DateTime.now();
  if (now.difference(last) < interval) return false;

  recordPushedAt(databasePath: databasePath, time: now);

  return pushContextDatabase(
    projectRoot: projectRoot,
    branch: branch,
    databaseFile: File(databasePath),
    fileName: fileName,
  );
}
