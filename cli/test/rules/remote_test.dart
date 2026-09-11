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

import 'package:cli/src/rules/remote.dart';
import 'package:test/test.dart';

void main() {
  test('fetches the real public corpus and splits it into global and project', () async {
    final remote = await fetchRemoteCorpus();

    expect(remote, isNotNull);
    expect(remote!.global, contains('rules.md'));
    expect(remote.global, contains('common/code.md'));
    expect(remote.project, contains('push.md'));
  });

  test('returns null when the host cannot be reached', () async {
    final remote = await fetchRemoteCorpus(
      source: Uri.https('codeload.invalid.example.test', '/daf-ep/workspace/tar.gz/refs/heads/main'),
      timeout: const Duration(seconds: 2),
    );

    expect(remote, isNull);
  });

  test('returns null on a non-200 response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) => (request.response..statusCode = HttpStatus.notFound).close());

    final remote = await fetchRemoteCorpus(source: Uri.http('${server.address.host}:${server.port}', '/'));

    expect(remote, isNull);
  });

  test('returns null when the response is not a valid archive', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen(
      (request) => request.response
        ..add([1, 2, 3, 4])
        ..close(),
    );

    final remote = await fetchRemoteCorpus(source: Uri.http('${server.address.host}:${server.port}', '/'));

    expect(remote, isNull);
  });

  test('times out rather than hanging when the server never answers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) {});

    final remote = await fetchRemoteCorpus(
      source: Uri.http('${server.address.host}:${server.port}', '/'),
      timeout: const Duration(milliseconds: 500),
    );

    expect(remote, isNull);
  });
}
