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

import 'package:archive/archive_io.dart';
import 'package:cli/src/rules/database.dart';
import 'package:cli/src/rules/update_check.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late String databasePath;
  late Directory projectRoot;
  late HttpServer server;
  late Uri fixtureSource;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('dpw_update_check_');
    databasePath = p.join(directory.path, 'rules.sqlite3');
    projectRoot = Directory(p.join(directory.path, 'project'))..createSync();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    fixtureSource = Uri.http('${server.address.host}:${server.port}', '/');
    server.listen((request) {
      request.response.add(
        _buildFixtureArchive(
          global: {'rules.md': 'fixture root rule', 'common/code.md': 'fixture code rule'},
          project: {'push.md': 'fixture default customization'},
        ),
      );
      request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    directory.deleteSync(recursive: true);
  });

  test('is not due when the interval since the last check has not passed', () async {
    await recordRemoteCheckAt(databasePath: databasePath, time: DateTime.now());

    final updated = await maybeCheckForRemoteUpdates(
      rulesDatabasePath: databasePath,
      projectRoot: projectRoot,
      interval: const Duration(days: 1),
      remoteSource: fixtureSource,
    );

    expect(updated, isFalse);
    expect(await readRule(databasePath: databasePath, name: 'rules', type: 'rules'), isNull);
  });

  test('a database that was never checked is due under the ordinary interval', () async {
    final updated = await maybeCheckForRemoteUpdates(
      rulesDatabasePath: databasePath,
      projectRoot: projectRoot,
      interval: const Duration(days: 1),
      remoteSource: fixtureSource,
    );

    expect(updated, isTrue);
  });

  test('an interval longer than the time since the epoch suppresses even a never-checked database', () async {
    final updated = await maybeCheckForRemoteUpdates(
      rulesDatabasePath: databasePath,
      projectRoot: projectRoot,
      interval: const Duration(days: 365 * 100),
      remoteSource: fixtureSource,
    );

    expect(updated, isFalse);
  });

  test('applies the fetched global content into the shared database', () async {
    await maybeCheckForRemoteUpdates(
      rulesDatabasePath: databasePath,
      projectRoot: projectRoot,
      interval: Duration.zero,
      remoteSource: fixtureSource,
    );

    expect(await readRule(databasePath: databasePath, name: 'rules', type: 'rules'), 'fixture root rule');
    expect(await readRule(databasePath: databasePath, name: 'code', type: 'common'), 'fixture code rule');
  });

  test('adds the fetched project content, without overwriting a file the project already wrote', () async {
    final dpwDir = Directory(p.join(projectRoot.path, '.claude', 'dpw'))..createSync(recursive: true);
    File(p.join(dpwDir.path, 'push.md')).writeAsStringSync('a project wrote this already');

    await maybeCheckForRemoteUpdates(
      rulesDatabasePath: databasePath,
      projectRoot: projectRoot,
      interval: Duration.zero,
      remoteSource: fixtureSource,
    );

    expect(File(p.join(dpwDir.path, 'push.md')).readAsStringSync(), 'a project wrote this already');
  });

  test('records the check even when the remote could not be reached', () async {
    final updated = await maybeCheckForRemoteUpdates(
      rulesDatabasePath: databasePath,
      projectRoot: projectRoot,
      interval: Duration.zero,
      remoteSource: Uri.https('codeload.invalid.example.test', '/daf-ep/workspace/tar.gz/refs/heads/main'),
    );

    expect(updated, isFalse);
    expect(await lastRemoteCheckAt(databasePath: databasePath), isNotNull);
  });
}

List<int> _buildFixtureArchive({required Map<String, String> global, required Map<String, String> project}) {
  final archive = Archive();

  void addFile(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  for (final entry in global.entries) {
    addFile('fixture-main/rules/global/${entry.key}', entry.value);
  }
  for (final entry in project.entries) {
    addFile('fixture-main/rules/project/${entry.key}', entry.value);
  }

  return GZipEncoder().encode(TarEncoder().encode(archive));
}
