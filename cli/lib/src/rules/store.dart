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

/// The corpus every project reads through `get_rule`, one copy for the whole
/// machine at [storeRoot]/`global/`, kept fresh by [replaceGlobalContent]
/// instead of a database: the content was already a directory of files
/// before it reached this store, and stays one.
///
/// Reading directly here, rather than through the checkout `dpw init` first
/// read from, is what lets the same store serve a project regardless of
/// whether that checkout is an installed copy beside the binary or the
/// working tree of whoever is developing dpw itself: only [storeRoot] is
/// ever written to, the checkout stays read-only.
String? readRule({required Directory storeRoot, required String name, required String type}) {
  final file = File(p.joinAll([storeRoot.path, 'global', ..._toSegments(type: type, name: name)]));
  return file.existsSync() ? file.readAsStringSync() : null;
}

/// Every (type, name) pair [readRule] can read from [storeRoot], sorted by
/// type then name.
List<({String type, String name})> listRules({required Directory storeRoot}) {
  final global = Directory(p.join(storeRoot.path, 'global'));
  if (!global.existsSync()) return const [];

  final entries = [
    for (final entity in global.listSync(recursive: true).whereType<File>())
      _parseSegments(p.split(p.relative(entity.path, from: global.path))),
  ];
  entries.sort((a, b) {
    final byType = a.type.compareTo(b.type);
    return byType != 0 ? byType : a.name.compareTo(b.name);
  });
  return entries;
}

/// Replaces `[storeRoot]/global/` with [contents], keyed by the
/// corpus-relative path each entry names, for example `rules.md` or
/// `common/code.md`.
///
/// Writes the new tree beside the old one, then swaps them with two
/// directory renames, so a reader calling [readRule] mid-write always sees
/// either the previous content or this one, never a half-written mix.
void replaceGlobalContent({required Directory storeRoot, required Map<String, String> contents}) {
  final target = Directory(p.join(storeRoot.path, 'global'));
  final staged = Directory(p.join(storeRoot.path, '.global.new'));
  final previous = Directory(p.join(storeRoot.path, '.global.old'));

  if (staged.existsSync()) staged.deleteSync(recursive: true);
  staged.createSync(recursive: true);
  for (final entry in contents.entries) {
    final file = File(p.joinAll([staged.path, ...entry.key.split('/')]));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
  }

  if (previous.existsSync()) previous.deleteSync(recursive: true);
  if (target.existsSync()) target.renameSync(previous.path);
  staged.renameSync(target.path);
  if (previous.existsSync()) previous.deleteSync(recursive: true);
}

/// When this machine last checked the public corpus for updates, or null
/// when it never has.
DateTime? lastCheckedAt({required Directory storeRoot}) {
  final file = File(p.join(storeRoot.path, 'last_checked'));
  if (!file.existsSync()) return null;
  return DateTime.tryParse(file.readAsStringSync().trim());
}

/// Records [time] as the last moment this machine checked the public corpus
/// for updates.
void recordCheckedAt({required Directory storeRoot, required DateTime time}) {
  storeRoot.createSync(recursive: true);
  File(p.join(storeRoot.path, 'last_checked')).writeAsStringSync(time.toIso8601String());
}

List<String> _toSegments({required String type, required String name}) =>
    type == 'rules' ? ['$name.md'] : [type, '$name.md'];

/// The inverse of [_toSegments]: splits a corpus-relative path like
/// `common/code.md` or `rules.md` into the (type, name) pair it names.
///
/// A path with no directory names the corpus entry point, whose type and
/// name are both `rules`.
({String type, String name}) _parseSegments(List<String> segments) {
  if (segments.length == 1) {
    return (type: 'rules', name: p.withoutExtension(segments.single));
  }
  return (type: segments.first, name: p.withoutExtension(segments.last));
}
