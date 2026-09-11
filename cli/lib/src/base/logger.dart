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

/// Everything this tool prints, so that no code writes to a stream itself.
///
/// The implementation decides where the text lands and how much of it
/// survives: [StdoutLogger] writes to the terminal, [BufferLogger] keeps it
/// for a test.
abstract class Logger {
  /// Whether [printError] was called at least once.
  ///
  /// The runner can read this after a command returns, the same way a thrown
  /// [ToolExit] carries its own exit code.
  bool get hadErrorOutput;

  /// Prints [message] on standard output.
  void printStatus(String message);

  /// Prints [message] on standard error, and marks the run as having failed.
  void printError(String message);
}

/// The [Logger] that writes to the real standard streams.
class StdoutLogger extends Logger {
  @override
  bool hadErrorOutput = false;

  @override
  void printStatus(String message) => stdout.writeln(message);

  @override
  void printError(String message) {
    hadErrorOutput = true;
    stderr.writeln(message);
  }
}

/// A [Logger] that keeps every message instead of printing it.
///
/// A command tested through the context this way never touches a real stream,
/// and the assertion reads exactly what a user would have seen.
class BufferLogger extends Logger {
  @override
  bool hadErrorOutput = false;

  final StringBuffer _status = StringBuffer();
  final StringBuffer _error = StringBuffer();

  /// Everything passed to [printStatus].
  String get statusText => _status.toString();

  /// Everything passed to [printError].
  String get errorText => _error.toString();

  @override
  void printStatus(String message) => _status.writeln(message);

  @override
  void printError(String message) {
    hadErrorOutput = true;
    _error.writeln(message);
  }
}
