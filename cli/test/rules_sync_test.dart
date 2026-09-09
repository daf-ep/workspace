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

import 'package:cli/src/rules_sync.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory source;
  late Directory destination;

  setUp(() {
    source = Directory.systemTemp.createTempSync('dafep_source_');
    destination = Directory.systemTemp.createTempSync('dafep_dest_');

    File(p.join(source.path, 'rules.md')).writeAsStringSync('root rule');
    final common = Directory(p.join(source.path, 'common'))..createSync();
    File(p.join(common.path, 'code.md')).writeAsStringSync('code rule');
    final customization = Directory(p.join(source.path, 'customization'))..createSync();
    File(p.join(customization.path, 'push.md')).writeAsStringSync('default customization');
  });

  tearDown(() {
    source.deleteSync(recursive: true);
    destination.deleteSync(recursive: true);
  });

  test('copies every top-level entry except customization', () {
    syncRules(source: source, destination: destination);

    expect(File(p.join(destination.path, 'rules.md')).readAsStringSync(), 'root rule');
    expect(File(p.join(destination.path, 'common', 'code.md')).readAsStringSync(), 'code rule');
  });

  test('adds a missing customization file without touching an existing one', () {
    final existing = Directory(p.join(destination.path, 'customization'))..createSync(recursive: true);
    File(p.join(existing.path, 'push.md')).writeAsStringSync('a project wrote this already');

    syncRules(source: source, destination: destination);

    expect(
      File(p.join(destination.path, 'customization', 'push.md')).readAsStringSync(),
      'a project wrote this already',
    );
  });

  test('adds a customization file the project never wrote', () {
    syncRules(source: source, destination: destination);

    expect(File(p.join(destination.path, 'customization', 'push.md')).readAsStringSync(), 'default customization');
  });

  test('replaces a stale top-level file on the second run', () {
    syncRules(source: source, destination: destination);
    File(p.join(source.path, 'rules.md')).writeAsStringSync('updated rule');

    syncRules(source: source, destination: destination);

    expect(File(p.join(destination.path, 'rules.md')).readAsStringSync(), 'updated rule');
  });
}
