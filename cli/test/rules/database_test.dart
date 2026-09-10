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

import 'package:cli/src/rules/database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late String databasePath;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('dpw_rules_database_');
    databasePath = p.join(directory.path, 'nested', 'rules.sqlite3');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  test('reads back a synced rule under a directory, by its type and name', () async {
    await syncRulesDatabase(databasePath: databasePath, contents: {'common/code.md': 'code rule'});

    expect(await readRule(databasePath: databasePath, name: 'code', type: 'common'), 'code rule');
  });

  test('reads back the corpus entry point under type and name "rules"', () async {
    await syncRulesDatabase(databasePath: databasePath, contents: {'rules.md': 'root rule'});

    expect(await readRule(databasePath: databasePath, name: 'rules', type: 'rules'), 'root rule');
  });

  test('returns null for a name never synced', () async {
    await syncRulesDatabase(databasePath: databasePath, contents: {'rules.md': 'root rule'});

    expect(await readRule(databasePath: databasePath, name: 'code', type: 'common'), isNull);
  });

  test('does not confuse two types that share the same name', () async {
    await syncRulesDatabase(
      databasePath: databasePath,
      contents: {'dart/comments.md': 'dart comments', 'js/comments.md': 'js comments'},
    );

    expect(await readRule(databasePath: databasePath, name: 'comments', type: 'dart'), 'dart comments');
    expect(await readRule(databasePath: databasePath, name: 'comments', type: 'js'), 'js comments');
  });

  test('lists every synced (type, name) pair, sorted', () async {
    await syncRulesDatabase(
      databasePath: databasePath,
      contents: {'rules.md': 'root rule', 'common/code.md': 'code rule', 'common/test.md': 'test rule'},
    );

    expect(await listRules(databasePath: databasePath), [
      (type: 'common', name: 'code'),
      (type: 'common', name: 'test'),
      (type: 'rules', name: 'rules'),
    ]);
  });

  test('a second sync replaces the corpus instead of adding to it', () async {
    await syncRulesDatabase(databasePath: databasePath, contents: {'common/code.md': 'first version'});
    await syncRulesDatabase(databasePath: databasePath, contents: {'rules.md': 'root rule'});

    expect(await readRule(databasePath: databasePath, name: 'code', type: 'common'), isNull);
    expect(await readRule(databasePath: databasePath, name: 'rules', type: 'rules'), 'root rule');
  });

  test('migrates a database that only ever knew rule_files, without losing its rows', () async {
    Directory(p.dirname(databasePath)).createSync(recursive: true);
    final db = sqlite3.open(databasePath);
    db.execute('''
      CREATE TABLE rule_files (
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        PRIMARY KEY (name, type)
      )
    ''');
    db.execute("INSERT INTO rule_files (name, type, content) VALUES ('rules', 'rules', 'root rule')");
    db.execute('PRAGMA user_version = 1');
    db.close();

    expect(await readRule(databasePath: databasePath, name: 'rules', type: 'rules'), 'root rule');
    expect(await lastRemoteCheckAt(databasePath: databasePath), isNull);

    await recordRemoteCheckAt(databasePath: databasePath, time: DateTime.utc(2026, 3, 5));
    expect(await lastRemoteCheckAt(databasePath: databasePath), _isAtSameMomentAs(DateTime.utc(2026, 3, 5)));
  });

  group('remote check state', () {
    test('is null before any check was ever recorded', () async {
      expect(await lastRemoteCheckAt(databasePath: databasePath), isNull);
    });

    test('reads back the exact time a check was recorded at', () async {
      final checkedAt = DateTime.utc(2026, 3, 5, 12, 30);

      await recordRemoteCheckAt(databasePath: databasePath, time: checkedAt);

      expect(await lastRemoteCheckAt(databasePath: databasePath), _isAtSameMomentAs(checkedAt));
    });

    test('a second record replaces the first rather than adding to it', () async {
      await recordRemoteCheckAt(databasePath: databasePath, time: DateTime.utc(2026, 3, 1));
      await recordRemoteCheckAt(databasePath: databasePath, time: DateTime.utc(2026, 3, 5));

      expect(await lastRemoteCheckAt(databasePath: databasePath), _isAtSameMomentAs(DateTime.utc(2026, 3, 5)));
    });
  });
}

Matcher _isAtSameMomentAs(DateTime expected) => predicate<DateTime>((actual) => actual.isAtSameMomentAs(expected));
