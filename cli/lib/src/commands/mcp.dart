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

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

import '../decisions.dart';
import '../globals.dart' as globals;
import '../rules/database.dart';
import '../runner/dpw_command.dart';

/// Runs the MCP server Claude Code talks to over stdio.
///
/// Claude Code starts and stops this process itself, once per session, so
/// this command's job ends the moment the server is listening: the process
/// stays alive on its own, for as long as the stdio channel does.
class McpCommand extends DpwCommand {
  @override
  final name = 'mcp';

  @override
  final description = 'Runs the MCP server Claude Code talks to, for reading the rules corpus and recording decisions.';

  @override
  Future<DpwCommandResult> runCommand() async {
    final projectId = await globals.projectId;
    DpwServer(
      stdioChannel(input: stdin, output: stdout),
      projectId: projectId,
    );

    return const DpwCommandResult.success();
  }
}

/// The MCP server exposing `get_rule`, `list_rules` and `record_decision` to
/// whatever client connects.
base class DpwServer extends MCPServer with ToolsSupport {
  /// Serves [channel], reading the rules corpus and recording decisions
  /// under [projectId].
  DpwServer(super.channel, {required this.projectId})
    : super.fromStreamChannel(
        implementation: Implementation(name: 'dpw', version: '1.0.0'),
        instructions:
            'Before writing any code, call get_rule with name "rules" and '
            'type "rules": it says how to write here, and names the rest of '
            'the corpus by name and type. A file that names another by a '
            'bare filename, with no type prefix, means one of the same type '
            'as the file you read it from; a name written as "type/name.md" '
            'names both directly. A path under "customization/" is not in '
            'this corpus: it is a real file, already synced under this '
            'project\'s .claude/rules/customization/, read it from there '
            'instead. Call list_rules if a lookup does not resolve.\n\n'
            'Call record_decision whenever you make a decision worth '
            'capturing: a choice made against at least one other option, '
            'with a verifiable reason and a consequence for whoever touches '
            'this path next. Do not call it for a plain rename, a rewrite in '
            'the same shape, or a dependency bump with no trade-off attached.',
      ) {
    registerTool(getRuleTool, _getRule);
    registerTool(listRulesTool, _listRules);
    registerTool(recordDecisionTool, _recordDecision);
  }

  /// The project this server's decisions are recorded under.
  final String projectId;

  /// The tool a client calls to read one file of the rules corpus.
  final Tool getRuleTool = Tool(
    name: 'get_rule',
    description:
        "Reads one file of this project's rules corpus, addressed by its "
        'name and type. type is one of "common", "dart", "js", or "rules" '
        '(the corpus entry point, itself named "rules"). Call list_rules '
        'first when either is not known.',
    inputSchema: Schema.object(
      properties: {
        'name': Schema.string(description: "The file's name, without its .md extension."),
        'type': Schema.string(description: 'One of "common", "dart", "js", or "rules".'),
      },
      required: ['name', 'type'],
    ),
  );

  /// The tool a client calls to see every (type, name) pair `get_rule` can
  /// read.
  final Tool listRulesTool = Tool(
    name: 'list_rules',
    description: 'Lists every type/name pair get_rule can read from the rules corpus.',
    inputSchema: Schema.object(properties: {}),
  );

  /// The tool a client calls to record one decision.
  final Tool recordDecisionTool = Tool(
    name: 'record_decision',
    description:
        "Records one decision in the project's context base. Every field is "
        'required: a record missing one of them is a note, not a decision.',
    inputSchema: Schema.object(
      properties: {
        'decided': Schema.string(description: 'What was decided, as a fact about the system today.'),
        'why': Schema.string(description: 'The reasoning, and what was ruled out.'),
        'implies': Schema.string(description: 'The consequence for whoever touches this next.'),
        'verified': Schema.string(description: 'What confirmed it works.'),
      },
      required: ['decided', 'why', 'implies', 'verified'],
    ),
  );

  Future<CallToolResult> _getRule(CallToolRequest request) async {
    final args = request.arguments!;
    final name = args['name'] as String;
    final type = args['type'] as String;
    final content = await readRule(databasePath: globals.rulesDatabasePath, name: name, type: type);
    if (content == null) {
      return CallToolResult(
        isError: true,
        content: [TextContent(text: 'No rule named "$name" of type "$type". Call list_rules to see what exists.')],
      );
    }
    return CallToolResult(content: [TextContent(text: content)]);
  }

  Future<CallToolResult> _listRules(CallToolRequest request) async {
    final rules = await listRules(databasePath: globals.rulesDatabasePath);
    final lines = rules.map((rule) => '${rule.type}/${rule.name}');
    return CallToolResult(content: [TextContent(text: lines.join('\n'))]);
  }

  Future<CallToolResult> _recordDecision(CallToolRequest request) async {
    final args = request.arguments!;
    final decision = Decision(
      decided: args['decided'] as String,
      why: args['why'] as String,
      implies: args['implies'] as String,
      verified: args['verified'] as String,
    );

    recordDecision(databasePath: globals.decisionsDatabasePath, projectId: projectId, decision: decision);

    return CallToolResult(content: [TextContent(text: 'Recorded: ${decision.decided}')]);
  }
}
