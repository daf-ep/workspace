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

import 'package:cli/src/context/encryption.dart';
import 'package:test/test.dart';

void main() {
  final keyBytes = List<int>.filled(contextKeyLength, 7);
  final otherKeyBytes = List<int>.filled(contextKeyLength, 9);

  test('decrypts exactly what was encrypted, under the same key', () async {
    final plainBytes = utf8.encode('a payload only the right key should ever read back');

    final blob = await encryptContext(plainBytes, keyBytes: keyBytes);
    final decrypted = await decryptContext(blob, keyBytes: keyBytes);

    expect(decrypted, plainBytes);
  });

  test('never produces the same blob twice for the same plain bytes', () async {
    final plainBytes = utf8.encode('same content, twice');

    final first = await encryptContext(plainBytes, keyBytes: keyBytes);
    final second = await encryptContext(plainBytes, keyBytes: keyBytes);

    expect(first, isNot(second));
  });

  test('the blob never contains the plain bytes as a readable substring', () async {
    const secret = 'a very specific secret the ciphertext must never show in the clear';
    final blob = await encryptContext(utf8.encode(secret), keyBytes: keyBytes);

    expect(utf8.decode(blob, allowMalformed: true), isNot(contains(secret)));
  });

  test('returns null when decrypting with the wrong key', () async {
    final blob = await encryptContext(utf8.encode('hello'), keyBytes: keyBytes);

    expect(await decryptContext(blob, keyBytes: otherKeyBytes), isNull);
  });

  test('returns null when the blob was tampered with', () async {
    final blob = await encryptContext(utf8.encode('hello'), keyBytes: keyBytes);
    final tampered = List<int>.from(blob)..[blob.length - 1] ^= 0xff;

    expect(await decryptContext(tampered, keyBytes: keyBytes), isNull);
  });

  test('returns null for a blob far too short to be one', () async {
    expect(await decryptContext([1, 2, 3], keyBytes: keyBytes), isNull);
  });
}
