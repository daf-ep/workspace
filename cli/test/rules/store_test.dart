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

import 'package:cli/src/rules/store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory storeRoot;

  setUp(() => storeRoot = Directory.systemTemp.createTempSync('dpw_rules_store_'));
  tearDown(() => storeRoot.deleteSync(recursive: true));

  test('reads back a synced rule under a directory, by its type and name', () {
    replaceGlobalContent(storeRoot: storeRoot, contents: {'common/code.md': 'code rule'});

    expect(readRule(storeRoot: storeRoot, name: 'code', type: 'common'), 'code rule');
  });

  test('reads back the corpus entry point under type and name "rules"', () {
    replaceGlobalContent(storeRoot: storeRoot, contents: {'rules.md': 'root rule'});

    expect(readRule(storeRoot: storeRoot, name: 'rules', type: 'rules'), 'root rule');
  });

  test('returns null for a name never synced', () {
    replaceGlobalContent(storeRoot: storeRoot, contents: {'rules.md': 'root rule'});

    expect(readRule(storeRoot: storeRoot, name: 'code', type: 'common'), isNull);
  });

  test('returns null before anything was ever synced', () {
    expect(readRule(storeRoot: storeRoot, name: 'rules', type: 'rules'), isNull);
    expect(listRules(storeRoot: storeRoot), isEmpty);
  });

  test('does not confuse two types that share the same name', () {
    replaceGlobalContent(
      storeRoot: storeRoot,
      contents: {'dart/comments.md': 'dart comments', 'js/comments.md': 'js comments'},
    );

    expect(readRule(storeRoot: storeRoot, name: 'comments', type: 'dart'), 'dart comments');
    expect(readRule(storeRoot: storeRoot, name: 'comments', type: 'js'), 'js comments');
  });

  test('lists every synced (type, name) pair, sorted', () {
    replaceGlobalContent(
      storeRoot: storeRoot,
      contents: {'rules.md': 'root rule', 'common/code.md': 'code rule', 'common/test.md': 'test rule'},
    );

    expect(listRules(storeRoot: storeRoot), [
      (type: 'common', name: 'code'),
      (type: 'common', name: 'test'),
      (type: 'rules', name: 'rules'),
    ]);
  });

  test('a second replace drops what the first wrote instead of adding to it', () {
    replaceGlobalContent(storeRoot: storeRoot, contents: {'common/code.md': 'first version'});
    replaceGlobalContent(storeRoot: storeRoot, contents: {'rules.md': 'root rule'});

    expect(readRule(storeRoot: storeRoot, name: 'code', type: 'common'), isNull);
    expect(readRule(storeRoot: storeRoot, name: 'rules', type: 'rules'), 'root rule');
  });

  test('leaves no staging or backup directory behind after a replace', () {
    replaceGlobalContent(storeRoot: storeRoot, contents: {'rules.md': 'first version'});
    replaceGlobalContent(storeRoot: storeRoot, contents: {'rules.md': 'second version'});

    expect(Directory(p.join(storeRoot.path, '.global.new')).existsSync(), isFalse);
    expect(Directory(p.join(storeRoot.path, '.global.old')).existsSync(), isFalse);
  });

  group('last checked time', () {
    test('is null before any check was ever recorded', () {
      expect(lastCheckedAt(storeRoot: storeRoot), isNull);
    });

    test('reads back the exact time a check was recorded at', () {
      final checkedAt = DateTime.utc(2026, 3, 5, 12, 30);

      recordCheckedAt(storeRoot: storeRoot, time: checkedAt);

      expect(lastCheckedAt(storeRoot: storeRoot), checkedAt);
    });

    test('a second record replaces the first rather than adding to it', () {
      recordCheckedAt(storeRoot: storeRoot, time: DateTime.utc(2026, 3, 1));
      recordCheckedAt(storeRoot: storeRoot, time: DateTime.utc(2026, 3, 5));

      expect(lastCheckedAt(storeRoot: storeRoot), DateTime.utc(2026, 3, 5));
    });
  });
}
