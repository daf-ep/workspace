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

import 'package:path/path.dart' as p;

import 'remote.dart';
import 'store.dart';
import 'sync.dart';

/// Checks the public corpus for updates when [interval] has passed since the
/// last check, refreshing the shared store and [projectRoot]'s
/// `.claude/dpw/` when it finds any. A store that has never been checked
/// counts as checked at the epoch, so it is always due.
///
/// Silent by design. Offline, or a check that is not due yet, are the
/// expected common case, not a failure to report: this never throws and
/// never prints anything on its own. The last-checked time is written
/// whether or not the fetch succeeds, so a machine that stays offline for a
/// while pays the network timeout at most once per [interval], not on every
/// single command.
///
/// Returns whether a real update was applied, so a caller can decide
/// whether that is worth telling the user about.
///
/// [remoteSource] overrides where the corpus is fetched from; a test uses it
/// to point at a fixture server instead of the public corpus.
Future<bool> maybeCheckForRemoteUpdates({
  required Directory rulesStoreRoot,
  required Directory projectRoot,
  required Duration interval,
  Uri? remoteSource,
}) async {
  final lastChecked = lastCheckedAt(storeRoot: rulesStoreRoot) ?? DateTime.fromMillisecondsSinceEpoch(0);
  final now = DateTime.now();
  if (now.difference(lastChecked) < interval) return false;

  recordCheckedAt(storeRoot: rulesStoreRoot, time: now);

  final remote = await fetchRemoteCorpus(source: remoteSource);
  if (remote == null) return false;

  replaceGlobalContent(storeRoot: rulesStoreRoot, contents: remote.global);
  syncProjectFiles(contents: remote.project, destination: Directory(p.join(projectRoot.path, '.claude', 'dpw')));
  return true;
}
