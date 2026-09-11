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
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cli/src/rules/store.dart';
import 'package:cli/src/rules/update_check.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late Directory rulesStoreRoot;
  late Directory projectRoot;
  late HttpServer server;
  late Uri fixtureSource;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('dpw_update_check_');
    rulesStoreRoot = Directory(p.join(directory.path, 'rules_store'));
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
    recordCheckedAt(storeRoot: rulesStoreRoot, time: DateTime.now());

    final updated = await maybeCheckForRemoteUpdates(
      rulesStoreRoot: rulesStoreRoot,
      projectRoot: projectRoot,
      interval: const Duration(days: 1),
      remoteSource: fixtureSource,
    );

    expect(updated, isFalse);
    expect(readRule(storeRoot: rulesStoreRoot, name: 'rules', type: 'rules'), isNull);
  });

  test('a store that was never checked is due under the ordinary interval', () async {
    final updated = await maybeCheckForRemoteUpdates(
      rulesStoreRoot: rulesStoreRoot,
      projectRoot: projectRoot,
      interval: const Duration(days: 1),
      remoteSource: fixtureSource,
    );

    expect(updated, isTrue);
  });

  test('an interval longer than the time since the epoch suppresses even a never-checked store', () async {
    final updated = await maybeCheckForRemoteUpdates(
      rulesStoreRoot: rulesStoreRoot,
      projectRoot: projectRoot,
      interval: const Duration(days: 365 * 100),
      remoteSource: fixtureSource,
    );

    expect(updated, isFalse);
  });

  test('applies the fetched global content into the shared store', () async {
    await maybeCheckForRemoteUpdates(
      rulesStoreRoot: rulesStoreRoot,
      projectRoot: projectRoot,
      interval: Duration.zero,
      remoteSource: fixtureSource,
    );

    expect(readRule(storeRoot: rulesStoreRoot, name: 'rules', type: 'rules'), 'fixture root rule');
    expect(readRule(storeRoot: rulesStoreRoot, name: 'code', type: 'common'), 'fixture code rule');
  });

  test('adds the fetched project content, without overwriting a file the project already wrote', () async {
    final dpwDir = Directory(p.join(projectRoot.path, '.claude', 'dpw'))..createSync(recursive: true);
    File(p.join(dpwDir.path, 'push.md')).writeAsStringSync('a project wrote this already');

    await maybeCheckForRemoteUpdates(
      rulesStoreRoot: rulesStoreRoot,
      projectRoot: projectRoot,
      interval: Duration.zero,
      remoteSource: fixtureSource,
    );

    expect(File(p.join(dpwDir.path, 'push.md')).readAsStringSync(), 'a project wrote this already');
  });

  test('records the check even when the remote could not be reached', () async {
    final updated = await maybeCheckForRemoteUpdates(
      rulesStoreRoot: rulesStoreRoot,
      projectRoot: projectRoot,
      interval: Duration.zero,
      remoteSource: Uri.https('codeload.invalid.example.test', '/daf-ep/workspace/tar.gz/refs/heads/main'),
    );

    expect(updated, isFalse);
    expect(lastCheckedAt(storeRoot: rulesStoreRoot), isNotNull);
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
