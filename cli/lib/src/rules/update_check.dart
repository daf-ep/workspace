// Copyright (C) 2026 Fiber
//
// This software is licensed under the PolyForm Noncommercial License 1.0.0. A
// copy of it is available at
// https://polyformproject.org/licenses/noncommercial/1.0.0, and in the LICENSE
// file at the root of this repository.
//
// What you may do:
// - Use, study, and modify this software for any noncommercial purpose,
//   including personal use, research, education, and use by a charitable,
//   public research, public safety, health, environmental, or government
//   institution.
// - Distribute copies of it, with or without your changes, for those same
//   noncommercial purposes.
//
// What you may not do:
// - Use this software, or a modified or combined version of it, in a
//   commercial product or service, or for any other commercial purpose.
// - Sublicense it, or transfer your licence to someone else.
//
// What you must do in return:
// - Keep this notice on every file you received it on.
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
/// `.claude/injectable/` when it finds any. A store that has never been checked
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
  syncProjectFiles(contents: remote.project, destination: Directory(p.join(projectRoot.path, '.claude', 'injectable')));
  return true;
}
