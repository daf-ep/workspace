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

import 'package:cli/src/mcp_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory project;
  late File configFile;

  setUp(() {
    project = Directory.systemTemp.createTempSync('dpw_mcp_config_');
    configFile = File(p.join(project.path, '.mcp.json'));
  });

  tearDown(() {
    project.deleteSync(recursive: true);
  });

  test('creates .mcp.json declaring the server when none exists', () {
    ensureMcpServerDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final servers = config['mcpServers'] as Map<String, dynamic>;

    expect(servers['dpw-decisions'], {
      'command': 'dpw',
      'args': ['mcp'],
    });
  });

  test('keeps a server the project already declared for itself', () {
    configFile.writeAsStringSync(
      jsonEncode({
        'mcpServers': {
          'some-other-server': {'command': 'other', 'args': <String>[]},
        },
      }),
    );

    ensureMcpServerDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final servers = config['mcpServers'] as Map<String, dynamic>;

    expect(servers['some-other-server'], isNotNull);
    expect(servers['dpw-decisions'], isNotNull);
  });

  test('keeps a top-level key that has nothing to do with mcpServers', () {
    configFile.writeAsStringSync(jsonEncode({'somethingElse': 'kept as is'}));

    ensureMcpServerDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;

    expect(config['somethingElse'], 'kept as is');
  });

  test('replaces its own stale entry rather than duplicating it', () {
    configFile.writeAsStringSync(
      jsonEncode({
        'mcpServers': {
          'dpw-decisions': {'command': 'stale-command', 'args': <String>[]},
        },
      }),
    );

    ensureMcpServerDeclared(project);

    final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final servers = config['mcpServers'] as Map<String, dynamic>;

    expect(servers['dpw-decisions'], {
      'command': 'dpw',
      'args': ['mcp'],
    });
    expect(servers.length, 1);
  });
}
