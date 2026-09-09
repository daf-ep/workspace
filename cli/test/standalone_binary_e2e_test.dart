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

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('a compiled binary with rules beside it finds them on its own', () async {
    final install = Directory.systemTemp.createTempSync('dpw_install_');
    final project = Directory.systemTemp.createTempSync('dpw_project_');
    addTearDown(() => install.deleteSync(recursive: true));
    addTearDown(() => project.deleteSync(recursive: true));

    final packageRoot = Directory.current.path;
    final binaryPath = p.join(install.path, 'dpw');

    final compile = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'exe',
      p.join(packageRoot, 'bin', 'dpw.dart'),
      '-o',
      binaryPath,
    ]);
    expect(compile.exitCode, 0, reason: compile.stderr.toString());

    await _copyDirectory(Directory(p.join(packageRoot, '..', 'rules')), Directory(p.join(install.path, 'rules')));

    final result = await Process.run(binaryPath, ['init'], workingDirectory: project.path);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(File(p.join(project.path, '.claude', 'rules', 'rules.md')).existsSync(), isTrue);
    expect(File(p.join(project.path, '.claude', 'ID')).existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  destination.createSync(recursive: true);
  for (final entity in source.listSync()) {
    final name = p.basename(entity.path);
    final targetPath = p.join(destination.path, name);
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    }
  }
}
