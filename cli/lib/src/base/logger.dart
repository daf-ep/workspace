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
