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

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const String _serverName = 'injectable-decisions';

/// Declares injectable's MCP server in `.mcp.json` under [projectRoot].
///
/// Only the `injectable-decisions` entry is touched: every other server a project
/// declared for itself, and every other top-level key in the file, is kept
/// exactly as it was. A project's own `.mcp.json` is customization no sync
/// should clobber, the same rule `.claude/injectable/` already follows.
void ensureMcpServerDeclared(Directory projectRoot) {
  final file = File(p.join(projectRoot.path, '.mcp.json'));

  final Map<String, dynamic> config = _readConfig(file);
  final servers = (config['mcpServers'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  servers[_serverName] = <String, dynamic>{
    'command': 'injectable',
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
