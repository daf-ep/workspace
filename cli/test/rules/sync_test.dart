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

import 'package:cli/src/rules/sync.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory source;

  setUp(() {
    source = Directory.systemTemp.createTempSync('dafep_source_');

    File(p.join(source.path, 'rules.md')).writeAsStringSync('root rule');
    final common = Directory(p.join(source.path, 'common'))..createSync();
    File(p.join(common.path, 'code.md')).writeAsStringSync('code rule');
    final customization = Directory(p.join(source.path, 'customization'))..createSync();
    File(p.join(customization.path, 'push.md')).writeAsStringSync('default customization');
  });

  tearDown(() => source.deleteSync(recursive: true));

  group('collectRuleContents', () {
    test('reads every file except customization, keyed by its relative path', () {
      final contents = collectRuleContents(source);

      expect(contents, {'rules.md': 'root rule', 'common/code.md': 'code rule'});
    });

    test('picks up a file added since the last read', () {
      File(p.join(source.path, 'rules.md')).writeAsStringSync('updated rule');

      expect(collectRuleContents(source)['rules.md'], 'updated rule');
    });
  });

  group('syncCustomization', () {
    late Directory destination;

    setUp(() => destination = Directory.systemTemp.createTempSync('dafep_dest_'));
    tearDown(() => destination.deleteSync(recursive: true));

    test('adds a customization file the project never wrote', () {
      syncCustomization(source: Directory(p.join(source.path, 'customization')), destination: destination);

      expect(File(p.join(destination.path, 'push.md')).readAsStringSync(), 'default customization');
    });

    test('never overwrites a customization file the project already wrote', () {
      destination.createSync(recursive: true);
      File(p.join(destination.path, 'push.md')).writeAsStringSync('a project wrote this already');

      syncCustomization(source: Directory(p.join(source.path, 'customization')), destination: destination);

      expect(File(p.join(destination.path, 'push.md')).readAsStringSync(), 'a project wrote this already');
    });
  });
}
