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

import 'package:cli/src/gitignore.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory project;
  late File file;

  setUp(() {
    project = Directory.systemTemp.createTempSync('injectable_gitignore_');
    file = File(p.join(project.path, '.gitignore'));
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('creates .gitignore with the pattern when none exists', () {
    ensureGitignored(project, '.claude/context');

    expect(file.readAsStringSync(), '.claude/context\n');
  });

  test('appends the pattern to an existing .gitignore that lacks a trailing newline', () {
    file.writeAsStringSync('node_modules/');

    ensureGitignored(project, '.claude/context');

    expect(file.readAsStringSync(), 'node_modules/\n.claude/context\n');
  });

  test('never adds the pattern twice', () {
    ensureGitignored(project, '.claude/context');
    ensureGitignored(project, '.claude/context');

    expect(file.readAsStringSync(), '.claude/context\n');
  });

  test('keeps every other line untouched', () {
    file.writeAsStringSync('node_modules/\nbuild/\n');

    ensureGitignored(project, '.claude/context');

    expect(file.readAsStringSync(), 'node_modules/\nbuild/\n.claude/context\n');
  });
}
