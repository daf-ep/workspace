import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('running init creates .claude/rules and .claude/ID for real', () async {
    final project = Directory.systemTemp.createTempSync('dafep_e2e_');
    addTearDown(() => project.deleteSync(recursive: true));

    final binPath = p.join(Directory.current.path, 'bin', 'dafep.dart');

    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      binPath,
      'init',
    ], workingDirectory: project.path);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(
      File(p.join(project.path, '.claude', 'rules', 'rules.md')).existsSync(),
      isTrue,
    );

    final id = File(
      p.join(project.path, '.claude', 'ID'),
    ).readAsStringSync().trim();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
