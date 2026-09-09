import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/init_command.dart';

/// Runs the `dafep` command with [arguments], returning its exit code.
Future<int> runDafep(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'dafep',
    'Sync the rules corpus into a project and manage its context.',
  )..addCommand(InitCommand());

  try {
    return await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    return 64;
  }
}
