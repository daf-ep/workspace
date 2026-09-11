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

import 'package:cryptography/cryptography.dart';

/// How many bytes [decryptContext] expects a key to be: 256 bits, what
/// [_algorithm] is keyed with.
const int contextKeyLength = 32;

AesGcm get _algorithm => AesGcm.with256bits();

/// Encrypts [plainBytes] under [keyBytes], returning nonce, ciphertext and
/// authentication tag concatenated into one blob: everything [decryptContext]
/// needs, and nothing a reader without [keyBytes] can make sense of.
///
/// A fresh, random nonce is drawn for every call, so encrypting the same
/// bytes twice never produces the same blob twice.
Future<List<int>> encryptContext(List<int> plainBytes, {required List<int> keyBytes}) async {
  final secretBox = await _algorithm.encrypt(plainBytes, secretKey: SecretKey(keyBytes));
  return secretBox.concatenation();
}

/// Decrypts a blob [encryptContext] produced under [keyBytes], or returns
/// null when [keyBytes] is wrong or [blob] was tampered with or corrupted:
/// the authentication tag [encryptContext] embeds catches both.
Future<List<int>?> decryptContext(List<int> blob, {required List<int> keyBytes}) async {
  try {
    final secretBox = SecretBox.fromConcatenation(
      blob,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return await _algorithm.decrypt(secretBox, secretKey: SecretKey(keyBytes));
  } catch (_) {
    return null;
  }
}
