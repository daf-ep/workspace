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

import 'dart:convert';
import 'dart:io';

import 'package:cli/src/context/database.dart';
import 'package:cli/src/context/encryption.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late String databasePath;
  final keyBytes = List<int>.filled(contextKeyLength, 7);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('dpw_context_database_');
    databasePath = p.join(directory.path, 'nested', 'context');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  test('records a raw event exactly as given, unparsed', () async {
    await recordRawEvent(
      databasePath: databasePath,
      keyBytes: keyBytes,
      hookEvent: 'stop',
      payload: '{"last_assistant_message":"hi"}',
    );

    final rows = await _selectDecrypted(databasePath, keyBytes, 'SELECT hook_event, payload FROM raw_events');

    expect(rows, hasLength(1));
    expect(rows.first['hook_event'], 'stop');
    expect(rows.first['payload'], '{"last_assistant_message":"hi"}');
  });

  test('keeps every recorded event, not just the last one', () async {
    await recordRawEvent(databasePath: databasePath, keyBytes: keyBytes, hookEvent: 'session-start', payload: '{}');
    await recordRawEvent(
      databasePath: databasePath,
      keyBytes: keyBytes,
      hookEvent: 'user-prompt-submit',
      payload: '{"prompt":"hello"}',
    );

    final rows = await _selectDecrypted(databasePath, keyBytes, 'SELECT * FROM raw_events');
    expect(rows, hasLength(2));
  });

  test('the bytes on disk never contain the plain payload', () async {
    const payload = 'a very specific secret the file must never show in the clear';
    await recordRawEvent(databasePath: databasePath, keyBytes: keyBytes, hookEvent: 'stop', payload: payload);

    final onDisk = utf8.decode(File(databasePath).readAsBytesSync(), allowMalformed: true);
    expect(onDisk, isNot(contains(payload)));
  });

  test('a wrong key cannot read what the right key wrote', () async {
    await recordRawEvent(databasePath: databasePath, keyBytes: keyBytes, hookEvent: 'stop', payload: '{}');

    final wrongKey = List<int>.filled(contextKeyLength, 9);
    await expectLater(
      recordRawEvent(databasePath: databasePath, keyBytes: wrongKey, hookEvent: 'stop', payload: '{}'),
      throwsA(isA<StateError>()),
    );
  });

  group('last pushed time', () {
    test('is null before any push was ever recorded', () async {
      expect(await lastPushedAt(databasePath: databasePath, keyBytes: keyBytes), isNull);
    });

    test('reads back the exact time a push was recorded at', () async {
      final pushedAt = DateTime.utc(2026, 3, 5, 12, 30);

      await recordPushedAt(databasePath: databasePath, keyBytes: keyBytes, time: pushedAt);

      expect(await lastPushedAt(databasePath: databasePath, keyBytes: keyBytes), pushedAt);
    });

    test('a second record replaces the first rather than adding to it', () async {
      await recordPushedAt(databasePath: databasePath, keyBytes: keyBytes, time: DateTime.utc(2026, 3, 1));
      await recordPushedAt(databasePath: databasePath, keyBytes: keyBytes, time: DateTime.utc(2026, 3, 5));

      expect(await lastPushedAt(databasePath: databasePath, keyBytes: keyBytes), DateTime.utc(2026, 3, 5));
    });
  });
}

Future<List<Row>> _selectDecrypted(String databasePath, List<int> keyBytes, String query) async {
  final plainBytes = await decryptContext(File(databasePath).readAsBytesSync(), keyBytes: keyBytes);
  final scratch = Directory.systemTemp.createTempSync('dpw_context_verify_');
  final plainFile = File(p.join(scratch.path, 'context.sqlite3'))..writeAsBytesSync(plainBytes!);
  try {
    final db = sqlite3.open(plainFile.path);
    try {
      return db.select(query);
    } finally {
      db.close();
    }
  } finally {
    scratch.deleteSync(recursive: true);
  }
}
