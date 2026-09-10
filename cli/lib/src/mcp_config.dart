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

const String _serverName = 'dpw-decisions';

/// Declares dpw's MCP server in `.mcp.json` under [projectRoot].
///
/// Only the `dpw-decisions` entry is touched: every other server a project
/// declared for itself, and every other top-level key in the file, is kept
/// exactly as it was. A project's own `.mcp.json` is customization no sync
/// should clobber, the same rule `rules/customization/` already follows.
void ensureMcpServerDeclared(Directory projectRoot) {
  final file = File(p.join(projectRoot.path, '.mcp.json'));

  final Map<String, dynamic> config = _readConfig(file);
  final servers = (config['mcpServers'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  servers[_serverName] = <String, dynamic>{
    'command': 'dpw',
    'args': ['mcp'],
  };
  config['mcpServers'] = servers;

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(config)}\n');
}

Map<String, dynamic> _readConfig(File file) {
  if (!file.existsSync()) return <String, dynamic>{};

  final content = file.readAsStringSync().trim();
  if (content.isEmpty) return <String, dynamic>{};

  return jsonDecode(content) as Map<String, dynamic>;
}
