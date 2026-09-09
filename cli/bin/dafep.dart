import 'dart:io';

import 'package:cli/src/dafep_runner.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runDafep(arguments);
}
