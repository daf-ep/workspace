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

/// Syncs [source] into [destination].
///
/// Every top-level entry gets replaced, except `customization`, whose files
/// only get added when missing: a project's own customizations never get
/// overwritten by a later sync.
void syncRules({required Directory source, required Directory destination}) {
  destination.createSync(recursive: true);

  for (final entry in source.listSync()) {
    final name = p.basename(entry.path);
    if (name == 'customization') continue;
    final targetPath = p.join(destination.path, name);
    _removeIfExists(targetPath);
    _copyPath(entry, targetPath);
  }

  final customizationSource = Directory(p.join(source.path, 'customization'));
  if (!customizationSource.existsSync()) return;

  final customizationDest = Directory(p.join(destination.path, 'customization'))..createSync(recursive: true);

  for (final file in customizationSource.listSync().whereType<File>()) {
    final destPath = p.join(customizationDest.path, p.basename(file.path));
    if (!File(destPath).existsSync()) {
      file.copySync(destPath);
    }
  }
}

void _removeIfExists(String path) {
  final type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.notFound) return;
  if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
  } else {
    File(path).deleteSync();
  }
}

void _copyPath(FileSystemEntity entity, String destinationPath) {
  if (entity is Directory) {
    Directory(destinationPath).createSync(recursive: true);
    for (final child in entity.listSync()) {
      _copyPath(child, p.join(destinationPath, p.basename(child.path)));
    }
  } else if (entity is File) {
    entity.copySync(destinationPath);
  }
}
