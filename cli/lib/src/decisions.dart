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
import 'package:sqlite3/sqlite3.dart';

/// One decision, carrying the four fields `context.md` requires.
class Decision {
  /// Wraps the four fields a decision always carries.
  const Decision({required this.decided, required this.why, required this.implies, required this.verified});

  /// What was decided, as a fact about the system today.
  final String decided;

  /// The reasoning, and what was ruled out.
  final String why;

  /// The consequence for whoever touches this next.
  final String implies;

  /// What confirmed it works.
  final String verified;
}

/// Records [decision] for [projectId] in the database at [databasePath].
///
/// Creates the database and its table the first time either is missing.
void recordDecision({required String databasePath, required String projectId, required Decision decision}) {
  Directory(p.dirname(databasePath)).createSync(recursive: true);

  final db = sqlite3.open(databasePath);
  try {
    db.execute('''
      CREATE TABLE IF NOT EXISTS decisions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL,
        decided TEXT NOT NULL,
        why TEXT NOT NULL,
        implies TEXT NOT NULL,
        verified TEXT NOT NULL,
        recorded_at TEXT NOT NULL
      )
    ''');

    db.execute(
      'INSERT INTO decisions (project_id, decided, why, implies, verified, recorded_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        projectId,
        decision.decided,
        decision.why,
        decision.implies,
        decision.verified,
        DateTime.now().toIso8601String(),
      ],
    );
  } finally {
    db.close();
  }
}
