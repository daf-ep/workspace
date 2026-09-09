import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../project_id.dart';
import '../rules_sync.dart';

/// Creates `.claude/rules` in the current directory and assigns this
/// project its id.
class InitCommand extends Command<int> {
  @override
  final name = 'init';

  @override
  final description =
      'Sync .claude/rules from this checkout and assign the project an id.';

  @override
  Future<int> run() async {
    final rulesSource = findRulesSource();
    if (rulesSource == null) {
      stderr.writeln('dafep: no rules directory found next to this tool');
      return 1;
    }

    final cwd = Directory.current.path;
    final rulesDest = Directory(p.join(cwd, '.claude', 'rules'));
    syncRules(source: rulesSource, destination: rulesDest);
    stdout.writeln('dafep: rules synced into ${rulesDest.path}');

    final idFile = File(p.join(cwd, '.claude', 'ID'));
    final id = ensureProjectId(idFile);
    if (id.created) {
      stdout.writeln('dafep: assigned this project id ${id.id}');
    } else {
      stdout.writeln('dafep: this project already has id ${id.id}');
    }

    return 0;
  }
}
