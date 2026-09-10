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
