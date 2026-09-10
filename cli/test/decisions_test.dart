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

import 'package:cli/src/decisions.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late String databasePath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dpw_decisions_');
    databasePath = p.join(dir.path, 'nested', 'decisions.sqlite3');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('creates the database and its table on the first call', () {
    recordDecision(
      databasePath: databasePath,
      projectId: 'project-a',
      decision: const Decision(decided: 'x', why: 'y', implies: 'z', verified: 'w'),
    );

    final db = sqlite3.open(databasePath);
    addTearDown(db.close);
    final rows = db.select('SELECT * FROM decisions');

    expect(rows, hasLength(1));
    expect(rows.first['project_id'], 'project-a');
    expect(rows.first['decided'], 'x');
  });

  test('keeps decisions from different projects apart', () {
    recordDecision(
      databasePath: databasePath,
      projectId: 'project-a',
      decision: const Decision(decided: 'a decision', why: 'y', implies: 'z', verified: 'w'),
    );
    recordDecision(
      databasePath: databasePath,
      projectId: 'project-b',
      decision: const Decision(decided: 'another decision', why: 'y', implies: 'z', verified: 'w'),
    );

    final db = sqlite3.open(databasePath);
    addTearDown(db.close);
    final projectA = db.select('SELECT * FROM decisions WHERE project_id = ?', ['project-a']);
    final projectB = db.select('SELECT * FROM decisions WHERE project_id = ?', ['project-b']);

    expect(projectA, hasLength(1));
    expect(projectB, hasLength(1));
    expect(projectA.first['decided'], 'a decision');
    expect(projectB.first['decided'], 'another decision');
  });
}
