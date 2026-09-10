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

/// Records one hook's raw stdin payload in the database at [databasePath],
/// as [hookEvent] named it, verbatim and unparsed.
///
/// This is the table a future processing pass reads from; nothing here
/// decides what a payload means. Creates the database and its tables the
/// first time either is missing.
void recordRawEvent({required String databasePath, required String hookEvent, required String payload}) {
  final db = _open(databasePath);
  try {
    db.execute('''
      CREATE TABLE IF NOT EXISTS raw_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hook_event TEXT NOT NULL,
        payload TEXT NOT NULL,
        recorded_at TEXT NOT NULL
      )
    ''');
    db.execute('INSERT INTO raw_events (hook_event, payload, recorded_at) VALUES (?, ?, ?)', [
      hookEvent,
      payload,
      DateTime.now().toIso8601String(),
    ]);
  } finally {
    db.close();
  }
}

/// When this project's context database was last pushed to its orphan
/// branch, or null when it never has.
DateTime? lastPushedAt({required String databasePath}) {
  final db = _open(databasePath);
  try {
    db.execute('CREATE TABLE IF NOT EXISTS push_state (id INTEGER PRIMARY KEY, pushed_at TEXT NOT NULL)');
    final rows = db.select('SELECT pushed_at FROM push_state WHERE id = 0');
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['pushed_at'] as String);
  } finally {
    db.close();
  }
}

/// Records [time] as the last moment this project's context database was
/// pushed to its orphan branch.
void recordPushedAt({required String databasePath, required DateTime time}) {
  final db = _open(databasePath);
  try {
    db.execute('CREATE TABLE IF NOT EXISTS push_state (id INTEGER PRIMARY KEY, pushed_at TEXT NOT NULL)');
    db.execute('INSERT OR REPLACE INTO push_state (id, pushed_at) VALUES (0, ?)', [time.toIso8601String()]);
  } finally {
    db.close();
  }
}

Database _open(String databasePath) {
  Directory(p.dirname(databasePath)).createSync(recursive: true);
  return sqlite3.open(databasePath);
}
