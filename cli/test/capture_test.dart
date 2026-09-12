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

import 'package:cli/src/capture.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late String databasePath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('injectable_captures_');
    databasePath = p.join(dir.path, 'nested', 'captures.sqlite3');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('creates the database and its table on the first call', () {
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'input', exchangeId: 'prompt-1', payload: Uint8List.fromList([1, 2, 3])),
    );

    final rows = pendingCaptures(databasePath: databasePath);

    expect(rows, hasLength(1));
    expect(rows.single.projectId, 'project-a');
    expect(rows.single.accountHost, 'github');
    expect(rows.single.accountLogin, 'kim');
    expect(rows.single.direction, 'input');
    expect(rows.single.exchangeId, 'prompt-1');
    expect(rows.single.payload, [1, 2, 3]);
  });

  test('input and output of the same turn share their exchange id', () {
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'input', exchangeId: 'prompt-1', payload: Uint8List.fromList([1])),
    );
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'output', exchangeId: 'prompt-1', payload: Uint8List.fromList([2])),
    );

    final rows = pendingCaptures(databasePath: databasePath);

    expect(rows.map((row) => row.exchangeId).toSet(), {'prompt-1'});
  });

  test('keeps captures from different projects apart', () {
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'input', exchangeId: 'prompt-1', payload: Uint8List.fromList([1])),
    );
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-b',
      accountHost: 'gitlab',
      accountLogin: 'sam',
      exchange: CapturedExchange(direction: 'output', exchangeId: 'prompt-1', payload: Uint8List.fromList([2])),
    );

    final rows = pendingCaptures(databasePath: databasePath);

    expect(rows, hasLength(2));
    expect(rows.where((row) => row.projectId == 'project-a'), hasLength(1));
    expect(rows.where((row) => row.projectId == 'project-b'), hasLength(1));
  });

  test('returns captures oldest first', () {
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'input', exchangeId: 'prompt-1', payload: Uint8List.fromList([1])),
    );
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'output', exchangeId: 'prompt-1', payload: Uint8List.fromList([2])),
    );

    final rows = pendingCaptures(databasePath: databasePath);

    expect(rows.map((row) => row.direction).toList(), ['input', 'output']);
  });

  test('deleteCapture removes only the targeted row', () {
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'input', exchangeId: 'prompt-1', payload: Uint8List.fromList([1])),
    );
    recordCapture(
      databasePath: databasePath,
      projectId: 'project-a',
      accountHost: 'github',
      accountLogin: 'kim',
      exchange: CapturedExchange(direction: 'output', exchangeId: 'prompt-1', payload: Uint8List.fromList([2])),
    );
    final toDelete = pendingCaptures(databasePath: databasePath).first;

    deleteCapture(databasePath: databasePath, id: toDelete.id);

    final remaining = pendingCaptures(databasePath: databasePath);
    expect(remaining, hasLength(1));
    expect(remaining.single.direction, 'output');
  });
}
