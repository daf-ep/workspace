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

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';

void main() {
  late Directory project;
  late String binPath;

  setUp(() {
    project = Directory.systemTemp.createTempSync('injectable_hook_command_e2e_');
    binPath = p.join(Directory.current.path, 'bin', 'injectable.dart');
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('succeeds without a stored session, since it never calls the backend', () async {
    await initFakeGitRepo(project);

    final exitCode = await _runHook(binPath, project, event: 'stop', payload: '{"last_assistant_message":"done"}');

    expect(exitCode, 0);
  });

  test('succeeds and writes nothing, called with no event name', () async {
    await initFakeGitRepo(project);

    final exitCode = await _runHook(binPath, project, event: null, payload: '{}');

    expect(exitCode, 0);
    expect(File(p.join(project.path, '.claude', 'context')).existsSync(), isFalse);
  });

  test('succeeds and writes nothing outside a git repository either', () async {
    final exitCode = await _runHook(binPath, project, event: 'stop', payload: '{}');

    expect(exitCode, 0);
    expect(File(p.join(project.path, '.claude', 'context')).existsSync(), isFalse);
  });

  test('drains a payload larger than a pipe buffer without blocking', () async {
    await initFakeGitRepo(project);
    final largePayload = '{"transcript":"${'x' * (256 * 1024)}"}';

    final exitCode = await _runHook(binPath, project, event: 'stop', payload: largePayload);

    expect(exitCode, 0);
  });
}

Future<int> _runHook(String binPath, Directory project, {required String? event, required String payload}) async {
  final process = await Process.start(
    Platform.resolvedExecutable,
    ['run', binPath, 'hook', ?event],
    workingDirectory: project.path,
    environment: {'INJECTABLE_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000'},
  );

  process.stdin.write(payload);
  await process.stdin.close();

  final stderrOutput = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;
  if (exitCode != 0) fail('injectable hook exited $exitCode:\n$stderrOutput');
  return exitCode;
}
