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
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// One exchange to record, already sealed under the backend's public key:
/// this store never receives, and never writes, plaintext.
class CapturedExchange {
  /// Wraps [direction], [exchangeId], and the already-sealed [payload].
  const CapturedExchange({required this.direction, required this.exchangeId, required this.payload});

  /// Which side of the exchange this is, `input` or `output`.
  final String direction;

  /// The id `dpw-backend` pairs this row's other half by: Claude Code's own
  /// `prompt_id`, shared by the `UserPromptSubmit` and `Stop` hook firings
  /// of the same turn. Input and output are sealed and recorded the moment
  /// each one is captured, never held back waiting for the other, so this
  /// id is what lets the backend reunite them after the fact instead of a
  /// row here trying to hold both.
  final String exchangeId;

  /// The sealed payload, opaque to this store.
  final Uint8List payload;
}

/// One row [pendingCaptures] read back: everything a sync attempt needs to
/// send it on, and the [id] that lets it remove the row once acknowledged.
class PendingCapture {
  /// Wraps every field a sync attempt reads off a stored row.
  const PendingCapture({
    required this.id,
    required this.projectId,
    required this.accountHost,
    required this.accountLogin,
    required this.direction,
    required this.exchangeId,
    required this.payload,
    required this.capturedAt,
  });

  /// This row's id in the database, what [deleteCapture] targets.
  final int id;

  /// The project (`gitProjectId`) this exchange was captured under.
  final String projectId;

  /// Which host the capturing account was connected through.
  final String accountHost;

  /// The capturing account's handle on [accountHost].
  final String accountLogin;

  /// Which side of the exchange this is, `input` or `output`.
  final String direction;

  /// The id this row's other half, if already captured, shares.
  final String exchangeId;

  /// The sealed payload, opaque to this store.
  final Uint8List payload;

  /// When this exchange was captured.
  final DateTime capturedAt;
}

/// Records [exchange] for [projectId], captured under the account
/// [accountLogin] on [accountHost], in the database at [databasePath].
///
/// Creates the database and its table the first time either is missing.
/// The row stays until [deleteCapture] removes it: this call never
/// overwrites or merges with an existing row, each exchange is its own row.
void recordCapture({
  required String databasePath,
  required String projectId,
  required String accountHost,
  required String accountLogin,
  required CapturedExchange exchange,
}) {
  final db = _open(databasePath);
  try {
    db.execute(
      'INSERT INTO pending_captures '
      '(project_id, account_host, account_login, direction, exchange_id, payload, captured_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        projectId,
        accountHost,
        accountLogin,
        exchange.direction,
        exchange.exchangeId,
        exchange.payload,
        DateTime.now().toIso8601String(),
      ],
    );
  } finally {
    db.close();
  }
}

/// Every capture at [databasePath] not yet removed by [deleteCapture],
/// oldest first: the order a sync attempt should send them in.
List<PendingCapture> pendingCaptures({required String databasePath}) {
  final db = _open(databasePath);
  try {
    final rows = db.select('SELECT * FROM pending_captures ORDER BY id ASC');
    return rows
        .map(
          (row) => PendingCapture(
            id: row['id'] as int,
            projectId: row['project_id'] as String,
            accountHost: row['account_host'] as String,
            accountLogin: row['account_login'] as String,
            direction: row['direction'] as String,
            exchangeId: row['exchange_id'] as String,
            payload: row['payload'] as Uint8List,
            capturedAt: DateTime.parse(row['captured_at'] as String),
          ),
        )
        .toList();
  } finally {
    db.close();
  }
}

/// Removes the capture [id] from [databasePath], once the backend has
/// acknowledged it: this store never keeps a copy of what it has already
/// handed off.
void deleteCapture({required String databasePath, required int id}) {
  final db = _open(databasePath);
  try {
    db.execute('DELETE FROM pending_captures WHERE id = ?', [id]);
  } finally {
    db.close();
  }
}

Database _open(String databasePath) {
  Directory(p.dirname(databasePath)).createSync(recursive: true);

  final db = sqlite3.open(databasePath);
  db.execute('''
    CREATE TABLE IF NOT EXISTS pending_captures (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id TEXT NOT NULL,
      account_host TEXT NOT NULL,
      account_login TEXT NOT NULL,
      direction TEXT NOT NULL,
      exchange_id TEXT NOT NULL,
      payload BLOB NOT NULL,
      captured_at TEXT NOT NULL
    )
  ''');
  return db;
}
