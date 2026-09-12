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

import 'dart:convert';
import 'dart:typed_data';

import 'package:cli/src/capture_seal.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

void main() {
  test('the backend, holding the private key, recovers the exact plaintext', () async {
    final recipient = await X25519().newKeyPair();
    final recipientPublicKey = await recipient.extractPublicKey();

    final sealed = await seal(
      plaintext: Uint8List.fromList(utf8.encode('refactor the login module')),
      recipientPublicKey: Uint8List.fromList(recipientPublicKey.bytes),
    );

    final opened = await _open(sealed, recipientKeyPair: recipient);

    expect(utf8.decode(opened), 'refactor the login module');
  });

  test('two calls for the same plaintext never produce the same blob', () async {
    final recipient = await X25519().newKeyPair();
    final recipientPublicKey = Uint8List.fromList((await recipient.extractPublicKey()).bytes);
    final plaintext = Uint8List.fromList(utf8.encode('same message twice'));

    final first = await seal(plaintext: plaintext, recipientPublicKey: recipientPublicKey);
    final second = await seal(plaintext: plaintext, recipientPublicKey: recipientPublicKey);

    expect(first, isNot(equals(second)));
  });

  test('a different recipient key cannot open what was sealed for another', () async {
    final recipient = await X25519().newKeyPair();
    final impostor = await X25519().newKeyPair();
    final recipientPublicKey = Uint8List.fromList((await recipient.extractPublicKey()).bytes);

    final sealed = await seal(
      plaintext: Uint8List.fromList(utf8.encode('secret')),
      recipientPublicKey: recipientPublicKey,
    );

    expect(() => _open(sealed, recipientKeyPair: impostor), throwsA(anything));
  });
}

/// Reverses [seal] using primitives independent of it, so this test proves
/// what [seal] produces is genuinely decryptable, without `capture_seal.dart`
/// ever needing to expose a decrypting function of its own: nothing in this
/// package should be able to open what it just sealed.
Future<List<int>> _open(Uint8List blob, {required SimpleKeyPair recipientKeyPair}) async {
  const ephemeralPublicKeyLength = 32;
  const nonceLength = 12;
  const macLength = 16;

  final ephemeralPublicKeyBytes = blob.sublist(0, ephemeralPublicKeyLength);
  final nonce = blob.sublist(ephemeralPublicKeyLength, ephemeralPublicKeyLength + nonceLength);
  final mac = blob.sublist(ephemeralPublicKeyLength + nonceLength, ephemeralPublicKeyLength + nonceLength + macLength);
  final cipherText = blob.sublist(ephemeralPublicKeyLength + nonceLength + macLength);

  final keyExchange = X25519();
  final sharedSecret = await keyExchange.sharedSecretKey(
    keyPair: recipientKeyPair,
    remotePublicKey: SimplePublicKey(ephemeralPublicKeyBytes, type: KeyPairType.x25519),
  );

  final derivedKey = await Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  ).deriveKey(secretKey: sharedSecret, nonce: ephemeralPublicKeyBytes, info: utf8.encode('dpw-capture-seal-v1'));

  return Chacha20.poly1305Aead().decrypt(
    SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
    secretKey: derivedKey,
  );
}
