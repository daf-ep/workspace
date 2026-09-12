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

import 'package:cryptography/cryptography.dart';

/// The info string [seal] binds its key derivation to, so a key derived here
/// can never be replayed against a derivation meant for another purpose.
const _sealInfo = 'dpw-capture-seal-v1';

/// Seals [plaintext] for whoever holds the private half of
/// [recipientPublicKey], the only party able to read it back.
///
/// An ECIES construction over X25519: a fresh ephemeral key pair per call
/// exchanges a secret with [recipientPublicKey], `HKDF-SHA256` turns that
/// into a one-time symmetric key, and `ChaCha20-Poly1305` seals [plaintext]
/// under it. Nothing here needs a native library: every primitive is pure
/// Dart, so this runs the same on every platform `dpw` builds for.
///
/// The result is one opaque blob: the 32-byte ephemeral public key, then the
/// cipher's nonce, then its authentication tag, then the ciphertext. Nobody
/// without the recipient's private key, not even whoever calls this
/// function, can open it back up.
Future<Uint8List> seal({required Uint8List plaintext, required Uint8List recipientPublicKey}) async {
  final keyExchange = X25519();
  final ephemeralKeyPair = await keyExchange.newKeyPair();
  final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

  final sharedSecret = await keyExchange.sharedSecretKey(
    keyPair: ephemeralKeyPair,
    remotePublicKey: SimplePublicKey(recipientPublicKey, type: KeyPairType.x25519),
  );

  final derivedKey = await Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  ).deriveKey(secretKey: sharedSecret, nonce: ephemeralPublicKey.bytes, info: utf8.encode(_sealInfo));

  final cipher = Chacha20.poly1305Aead();
  final secretBox = await cipher.encrypt(plaintext, secretKey: derivedKey);

  return Uint8List.fromList([
    ...ephemeralPublicKey.bytes,
    ...secretBox.nonce,
    ...secretBox.mac.bytes,
    ...secretBox.cipherText,
  ]);
}
