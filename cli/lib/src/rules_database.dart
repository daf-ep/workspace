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

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

part 'rules_database.g.dart';

/// One file of the rules corpus, keyed by its path relative to the `rules/`
/// checkout, for example `rules.md` or `common/code.md`.
class RuleFiles extends Table {
  /// The file's path, relative to the corpus root, forward-slash separated.
  TextColumn get path => text()();

  /// The file's full text.
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {path};
}

/// The database every project on this machine shares, holding one copy of
/// the corpus instead of one copy per project.
@DriftDatabase(tables: [RuleFiles])
class RulesDatabase extends _$RulesDatabase {
  RulesDatabase._(super.executor);

  @override
  int get schemaVersion => 1;
}

/// Replaces every row in [databasePath] with [contents], keyed by path.
///
/// Runs as a single transaction, so a reader never sees a half-replaced
/// corpus: either the previous sync's rows or this one's, never a mix.
Future<void> syncRulesDatabase({required String databasePath, required Map<String, String> contents}) async {
  final database = _open(databasePath);
  try {
    await database.transaction(() async {
      await database.delete(database.ruleFiles).go();
      for (final entry in contents.entries) {
        await database
            .into(database.ruleFiles)
            .insert(RuleFilesCompanion.insert(path: entry.key, content: entry.value));
      }
    });
  } finally {
    await database.close();
  }
}

/// The text at [path] in the database at [databasePath], or null when no
/// rule file was ever synced under that path.
Future<String?> readRule({required String databasePath, required String path}) async {
  final database = _open(databasePath);
  try {
    final row = await (database.select(database.ruleFiles)..where((r) => r.path.equals(path))).getSingleOrNull();
    return row?.content;
  } finally {
    await database.close();
  }
}

/// Every path the database at [databasePath] carries, sorted.
Future<List<String>> listRulePaths({required String databasePath}) async {
  final database = _open(databasePath);
  try {
    final rows = await database.select(database.ruleFiles).get();
    return rows.map((row) => row.path).toList()..sort();
  } finally {
    await database.close();
  }
}

RulesDatabase _open(String databasePath) {
  Directory(p.dirname(databasePath)).createSync(recursive: true);
  return RulesDatabase._(NativeDatabase(File(databasePath)));
}
