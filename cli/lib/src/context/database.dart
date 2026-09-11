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

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'encryption.dart';

/// Records one hook's raw stdin payload in the encrypted database at
/// [databasePath], as [hookEvent] named it, verbatim and unparsed.
///
/// This is the table a future processing pass reads from; nothing here
/// decides what a payload means. Creates the database and its tables the
/// first time either is missing.
Future<void> recordRawEvent({
  required String databasePath,
  required List<int> keyBytes,
  required String hookEvent,
  required String payload,
}) {
  return _withDecryptedDatabase(databasePath, keyBytes, (db) {
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
  });
}

/// When this project's context database was last pushed to its orphan
/// branch, or null when it never has.
Future<DateTime?> lastPushedAt({required String databasePath, required List<int> keyBytes}) {
  return _withDecryptedDatabase(databasePath, keyBytes, (db) {
    db.execute('CREATE TABLE IF NOT EXISTS push_state (id INTEGER PRIMARY KEY, pushed_at TEXT NOT NULL)');
    final rows = db.select('SELECT pushed_at FROM push_state WHERE id = 0');
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['pushed_at'] as String);
  });
}

/// Records [time] as the last moment this project's context database was
/// pushed to its orphan branch.
Future<void> recordPushedAt({required String databasePath, required List<int> keyBytes, required DateTime time}) {
  return _withDecryptedDatabase(databasePath, keyBytes, (db) {
    db.execute('CREATE TABLE IF NOT EXISTS push_state (id INTEGER PRIMARY KEY, pushed_at TEXT NOT NULL)');
    db.execute('INSERT OR REPLACE INTO push_state (id, pushed_at) VALUES (0, ?)', [time.toIso8601String()]);
  });
}

/// Decrypts [databasePath] into a real sqlite file only [body] ever sees,
/// then re-encrypts whatever [body] left there back over [databasePath]:
/// the bytes on disk, before and after, are never anything but ciphertext.
///
/// A [databasePath] that does not exist yet starts [body] with an empty
/// database, the same way an ordinary sqlite path would. A [databasePath]
/// that exists but does not decrypt under [keyBytes], wrong key or a
/// tampered file, throws rather than silently starting [body] from empty:
/// losing every row already recorded is worse than failing loudly.
Future<T> _withDecryptedDatabase<T>(
  String databasePath,
  List<int> keyBytes,
  FutureOr<T> Function(Database database) body,
) async {
  final scratch = Directory.systemTemp.createTempSync('dpw_context_');
  final plainFile = File(p.join(scratch.path, 'context.sqlite3'));
  try {
    final encryptedFile = File(databasePath);
    if (encryptedFile.existsSync()) {
      final plainBytes = await decryptContext(encryptedFile.readAsBytesSync(), keyBytes: keyBytes);
      if (plainBytes == null) {
        throw StateError('dpw: $databasePath did not decrypt under the configured key.');
      }
      plainFile.writeAsBytesSync(plainBytes);
    }

    final db = sqlite3.open(plainFile.path);
    final T result;
    try {
      result = await body(db);
    } finally {
      db.close();
    }

    final newPlainBytes = plainFile.readAsBytesSync();
    final newEncryptedBytes = await encryptContext(newPlainBytes, keyBytes: keyBytes);
    Directory(p.dirname(databasePath)).createSync(recursive: true);
    encryptedFile.writeAsBytesSync(newEncryptedBytes);
    return result;
  } finally {
    scratch.deleteSync(recursive: true);
  }
}
