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

import 'package:path/path.dart' as p;

/// The command dpw registers for each hook event it listens on, keyed by
/// the event name Claude Code fires.
const Map<String, String> hookCommands = {
  'SessionStart': 'dpw hook session-start',
  'UserPromptSubmit': 'dpw hook user-prompt-submit',
  'Stop': 'dpw hook stop',
};

/// Declares dpw's hooks in `.claude/settings.json` under [projectRoot].
///
/// Only the matcher group carrying one of [hookCommands] is touched, added
/// if missing and replaced if already present: every other group a project
/// declared for itself under the same event, and every other top-level key
/// in the file, is kept exactly as it was.
void ensureHooksDeclared(Directory projectRoot) {
  final file = File(p.join(projectRoot.path, '.claude', 'settings.json'));

  final Map<String, dynamic> config = _readConfig(file);
  final hooks = (config['hooks'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  for (final entry in hookCommands.entries) {
    hooks[entry.key] = _withDpwGroup(hooks[entry.key], command: entry.value);
  }
  config['hooks'] = hooks;

  file.parent.createSync(recursive: true);
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(config)}\n');
}

List<dynamic> _withDpwGroup(dynamic existingGroups, {required String command}) {
  final groups = (existingGroups as List<dynamic>?)?.cast<Map<String, dynamic>>().toList() ?? <Map<String, dynamic>>[];

  groups.removeWhere((group) {
    final entries = (group['hooks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];
    return entries.length == 1 && entries.single['command'] == command;
  });

  groups.add(<String, dynamic>{
    'hooks': [
      <String, dynamic>{'type': 'command', 'command': command, 'timeout': 30},
    ],
  });

  return groups;
}

Map<String, dynamic> _readConfig(File file) {
  if (!file.existsSync()) return <String, dynamic>{};

  final content = file.readAsStringSync().trim();
  if (content.isEmpty) return <String, dynamic>{};

  return jsonDecode(content) as Map<String, dynamic>;
}
