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

import 'package:cli/src/rules/database.dart';
import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';

void main() {
  test('a real client can read the synced rules corpus through get_rule and list_rules', () async {
    final project = Directory.systemTemp.createTempSync('dpw_rules_mcp_e2e_project_');
    final rulesDatabaseDir = Directory.systemTemp.createTempSync('dpw_rules_mcp_e2e_db_');
    addTearDown(() => project.deleteSync(recursive: true));
    addTearDown(() => rulesDatabaseDir.deleteSync(recursive: true));
    await initFakeGitRepo(project, remote: 'git@github.com:dpw-tests/rules-mcp-e2e.git');

    final rulesDatabasePath = p.join(rulesDatabaseDir.path, 'rules.sqlite3');
    await syncRulesDatabase(
      databasePath: rulesDatabasePath,
      contents: {'rules.md': 'How We Work', 'common/code.md': 'Write code that reads back cleanly.'},
    );

    final binPath = p.join(Directory.current.path, 'bin', 'dpw.dart');

    final client = MCPClient(Implementation(name: 'rules_mcp_e2e_test', version: '0.0.1'));
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', binPath, 'mcp'],
      workingDirectory: project.path,
      environment: {'DPW_RULES_DATABASE': rulesDatabasePath, 'DPW_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000'},
    );
    addTearDown(process.kill);

    final server = client.connectServer(stdioChannel(input: process.stdout, output: process.stdin));

    await server.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: client.capabilities,
        clientInfo: client.implementation,
      ),
    );
    server.notifyInitialized();

    final tools = await server.listTools(ListToolsRequest());
    expect(tools.tools.map((tool) => tool.name), containsAll(['get_rule', 'list_rules']));

    final listResult = await server.callTool(CallToolRequest(name: 'list_rules', arguments: {}));
    expect(listResult.isError, isNot(true));
    final listedText = (listResult.content.single as TextContent).text;
    expect(listedText.split('\n'), ['common/code', 'rules/rules']);

    final getResult = await server.callTool(
      CallToolRequest(name: 'get_rule', arguments: {'name': 'code', 'type': 'common'}),
    );
    expect(getResult.isError, isNot(true));
    expect((getResult.content.single as TextContent).text, 'Write code that reads back cleanly.');

    final missingResult = await server.callTool(
      CallToolRequest(name: 'get_rule', arguments: {'name': 'missing', 'type': 'common'}),
    );
    expect(missingResult.isError, true);

    await client.shutdown();
  });
}
