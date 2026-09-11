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
