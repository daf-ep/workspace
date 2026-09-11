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

import 'package:path/path.dart' as p;

/// Finds the rules directory that ships next to this tool.
///
/// A compiled, installed binary carries its own copy right beside it, the
/// same way the installer unpacked it. Running from source instead, inside
/// this checkout, has no such copy: this walks up from the running script to
/// the package root, the first parent carrying a `pubspec.yaml`, then looks
/// for a sibling `rules` directory there.
Directory? findRulesSource() {
  final besideBinary = Directory(p.join(p.dirname(Platform.resolvedExecutable), 'rules'));
  if (besideBinary.existsSync()) return besideBinary;

  final scriptPath = File.fromUri(Platform.script).resolveSymbolicLinksSync();
  var dir = Directory(p.dirname(scriptPath));
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
  final rules = Directory(p.join(dir.parent.path, 'rules'));
  return rules.existsSync() ? rules : null;
}

/// Reads every file under `global/` in [rulesSource], keyed by its path
/// relative to `global/`, forward-slash separated.
///
/// This is what a sync writes into the shared rules store: the corpus
/// content every project reads the same copy of.
Map<String, String> collectRuleContents(Directory rulesSource) {
  final global = Directory(p.join(rulesSource.path, 'global'));
  final contents = <String, String>{};
  for (final entity in global.listSync(recursive: true).whereType<File>()) {
    final relative = p.relative(entity.path, from: global.path);
    contents[p.split(relative).join('/')] = entity.readAsStringSync();
  }
  return contents;
}

/// Reads every file directly under `project/` in [rulesSource], keyed by
/// its file name: `project/` is never nested, unlike `global/`.
Map<String, String> collectProjectContents(Directory rulesSource) {
  final project = Directory(p.join(rulesSource.path, 'project'));
  if (!project.existsSync()) return const {};
  return {for (final file in project.listSync().whereType<File>()) p.basename(file.path): file.readAsStringSync()};
}

/// Ensures every entry in [contents] exists under [destination] as a file
/// named by its key, without ever overwriting one already there.
///
/// A project's own customizations are never touched by a later sync: this
/// only adds a file the corpus ships when the project has no version of its
/// own yet.
void syncProjectFiles({required Map<String, String> contents, required Directory destination}) {
  destination.createSync(recursive: true);
  for (final entry in contents.entries) {
    final destPath = p.join(destination.path, entry.key);
    if (!File(destPath).existsSync()) {
      File(destPath).writeAsStringSync(entry.value);
    }
  }
}
