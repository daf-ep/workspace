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

import 'package:cli/src/settings_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory project;
  late File configFile;

  setUp(() {
    project = Directory.systemTemp.createTempSync('dpw_settings_config_');
    configFile = File(p.join(project.path, '.claude', 'settings.json'));
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('creates .claude/settings.json declaring every hook when none exists', () {
    ensureHooksDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final hooks = config['hooks'] as Map<String, dynamic>;

    for (final entry in hookCommands.entries) {
      final groups = hooks[entry.key] as List<dynamic>;
      expect(groups, [
        {
          'hooks': [
            {'type': 'command', 'command': entry.value, 'timeout': 30},
          ],
        },
      ]);
    }
  });

  test('keeps a hook group the project already declared for itself, on the same event', () {
    configFile.parent.createSync(recursive: true);
    configFile.writeAsStringSync(
      jsonEncode({
        'hooks': {
          'Stop': [
            {
              'hooks': [
                {'type': 'command', 'command': 'some-other-tool --on-stop'},
              ],
            },
          ],
        },
      }),
    );

    ensureHooksDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final hooks = config['hooks'] as Map<String, dynamic>;
    final stopGroups = (hooks['Stop'] as List<dynamic>).cast<Map<String, dynamic>>();

    expect(stopGroups, hasLength(2));
    expect(
      stopGroups.any(
        (group) => (group['hooks'] as List<dynamic>).cast<Map<String, dynamic>>().any(
          (hook) => hook['command'] == 'some-other-tool --on-stop',
        ),
      ),
      isTrue,
    );
  });

  test('keeps a top-level key that has nothing to do with hooks', () {
    configFile.parent.createSync(recursive: true);
    configFile.writeAsStringSync(jsonEncode({'somethingElse': 'kept as is'}));

    ensureHooksDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;

    expect(config['somethingElse'], 'kept as is');
  });

  test('replaces its own stale group rather than duplicating it', () {
    configFile.parent.createSync(recursive: true);
    configFile.writeAsStringSync(
      jsonEncode({
        'hooks': {
          'SessionStart': [
            {
              'hooks': [
                {'type': 'command', 'command': 'dpw hook session-start', 'timeout': 5},
              ],
            },
          ],
        },
      }),
    );

    ensureHooksDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final hooks = config['hooks'] as Map<String, dynamic>;
    final groups = hooks['SessionStart'] as List<dynamic>;

    expect(groups, [
      {
        'hooks': [
          {'type': 'command', 'command': 'dpw hook session-start', 'timeout': 30},
        ],
      },
    ]);
  });
}
