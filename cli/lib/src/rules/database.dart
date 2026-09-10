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

part 'database.g.dart';

/// One file of the rules corpus: its [type] is the top-level directory it
/// ships under (`common`, `dart`, `js`), or `rules` for the corpus entry
/// point, which has no directory of its own and is named `rules` under
/// both fields.
class RuleFiles extends Table {
  /// The file's name, without its `.md` extension.
  TextColumn get name => text()();

  /// The corpus directory this file ships under, or `rules` for the entry
  /// point.
  TextColumn get type => text()();

  /// The file's full text.
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {name, type};
}

/// When this machine last checked the public corpus for updates, a single
/// row keyed by [id], always `0`.
class RemoteSyncState extends Table {
  /// Always `0`: this table never carries more than one row.
  IntColumn get id => integer().withDefault(const Constant(0))();

  /// When the last check happened, whether or not it found the corpus
  /// reachable.
  DateTimeColumn get lastCheckedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The database every project on this machine shares, holding one copy of
/// the corpus instead of one copy per project.
@DriftDatabase(tables: [RuleFiles, RemoteSyncState])
class RulesDatabase extends _$RulesDatabase {
  RulesDatabase._(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(remoteSyncState);
    },
  );
}

/// Replaces every row in [databasePath] with [contents], keyed by the
/// corpus-relative path each entry names, for example `rules.md` or
/// `common/code.md`.
///
/// Runs as a single transaction, so a reader never sees a half-replaced
/// corpus: either the previous sync's rows or this one's, never a mix.
Future<void> syncRulesDatabase({required String databasePath, required Map<String, String> contents}) async {
  final database = _open(databasePath);
  try {
    await database.transaction(() async {
      await database.delete(database.ruleFiles).go();
      for (final entry in contents.entries) {
        final parsed = _parsePath(entry.key);
        await database
            .into(database.ruleFiles)
            .insert(RuleFilesCompanion.insert(name: parsed.name, type: parsed.type, content: entry.value));
      }
    });
  } finally {
    await database.close();
  }
}

/// The text of the file named [name] of [type] in the database at
/// [databasePath], or null when no such file was ever synced.
Future<String?> readRule({required String databasePath, required String name, required String type}) async {
  final database = _open(databasePath);
  try {
    final row = await (database.select(
      database.ruleFiles,
    )..where((r) => r.name.equals(name) & r.type.equals(type))).getSingleOrNull();
    return row?.content;
  } finally {
    await database.close();
  }
}

/// Every (type, name) pair the database at [databasePath] carries, sorted
/// by type then name.
Future<List<({String type, String name})>> listRules({required String databasePath}) async {
  final database = _open(databasePath);
  try {
    final rows = await database.select(database.ruleFiles).get();
    final entries = rows.map((row) => (type: row.type, name: row.name)).toList()
      ..sort((a, b) {
        final byType = a.type.compareTo(b.type);
        return byType != 0 ? byType : a.name.compareTo(b.name);
      });
    return entries;
  } finally {
    await database.close();
  }
}

/// When this machine last checked the public corpus for updates, or null
/// when it never has.
Future<DateTime?> lastRemoteCheckAt({required String databasePath}) async {
  final database = _open(databasePath);
  try {
    final row = await (database.select(database.remoteSyncState)..where((r) => r.id.equals(0))).getSingleOrNull();
    return row?.lastCheckedAt;
  } finally {
    await database.close();
  }
}

/// Records [time] as the last moment this machine checked the public corpus
/// for updates.
Future<void> recordRemoteCheckAt({required String databasePath, required DateTime time}) async {
  final database = _open(databasePath);
  try {
    await database
        .into(database.remoteSyncState)
        .insertOnConflictUpdate(RemoteSyncStateCompanion.insert(id: const Value(0), lastCheckedAt: time));
  } finally {
    await database.close();
  }
}

RulesDatabase _open(String databasePath) {
  Directory(p.dirname(databasePath)).createSync(recursive: true);
  return RulesDatabase._(NativeDatabase(File(databasePath)));
}

/// Splits a corpus-relative path like `common/code.md` or `rules.md` into
/// the (type, name) pair [RuleFiles] keys a row by.
///
/// A path with no directory names the corpus entry point, whose type and
/// name are both `rules`.
({String type, String name}) _parsePath(String path) {
  final segments = path.split('/');
  if (segments.length == 1) {
    return (type: 'rules', name: p.withoutExtension(segments.single));
  }
  return (type: segments.first, name: p.withoutExtension(segments.last));
}
