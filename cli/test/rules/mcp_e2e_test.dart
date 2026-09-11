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

import 'dart:io';

import 'package:cli/src/rules/store.dart';
import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/fake_git_repo.dart';
import '../support/fake_session.dart';

void main() {
  test('a real client can read the synced rules corpus through get_rule and list_rules', () async {
    final project = Directory.systemTemp.createTempSync('injectable_rules_mcp_e2e_project_');
    final rulesStoreRoot = Directory.systemTemp.createTempSync('injectable_rules_mcp_e2e_store_');
    addTearDown(() => project.deleteSync(recursive: true));
    addTearDown(() => rulesStoreRoot.deleteSync(recursive: true));
    await initFakeGitRepo(project, remote: 'git@github.com:injectable-tests/rules-mcp-e2e.git');

    replaceGlobalContent(
      storeRoot: rulesStoreRoot,
      contents: {'rules.md': 'How We Work', 'common/code.md': 'Write code that reads back cleanly.'},
    );

    final binPath = p.join(Directory.current.path, 'bin', 'injectable.dart');

    final client = MCPClient(Implementation(name: 'rules_mcp_e2e_test', version: '0.0.1'));
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', binPath, 'mcp'],
      workingDirectory: project.path,
      environment: {
        'INJECTABLE_RULES_DIR': rulesStoreRoot.path,
        'INJECTABLE_UPDATE_CHECK_INTERVAL_SECONDS': '315360000000',
        'INJECTABLE_CREDENTIALS_PATH': writeFakeSession(rulesStoreRoot),
      },
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
