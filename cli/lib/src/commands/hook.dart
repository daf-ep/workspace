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
import 'dart:typed_data';

import '../capture.dart';
import '../capture_seal.dart';
import '../globals.dart' as globals;
import '../runner/injectable_command.dart';

/// The field each event's JSON payload carries the text to capture in, keyed
/// by the direction it becomes once sealed. Claude Code names these fields
/// itself; see the hooks reference for `UserPromptSubmit` and `Stop`.
const _textFieldByDirection = {'input': 'user_input', 'output': 'last_assistant_message'};

/// Which [_textFieldByDirection] direction a hook event name captures, or
/// null for an event this command has nothing to record for (`SessionStart`
/// today).
const _directionByEvent = {'user-prompt-submit': 'input', 'stop': 'output'};

/// Records one Claude Code hook event, for later processing.
///
/// This is what `.claude/settings.json` calls for `SessionStart`,
/// `UserPromptSubmit` and `Stop`, one event name per registration. Never
/// fails: a hook Claude Code is waiting on has no use for an error from a
/// capture mechanism that is not part of what the user asked it to do.
///
/// `UserPromptSubmit` and `Stop` are the two directions of one exchange,
/// Claude Code's own `prompt_id` pairing them back up on `dpw-backend`'s
/// side: each is sealed and recorded the moment this command sees it,
/// never held back waiting for the other half to arrive. `SessionStart`
/// carries nothing this command captures yet.
///
/// Capture stays inert, draining stdin and recording nothing, until both
/// [globals.storedSession] and [globals.capturePublicKey] are set: no
/// account to scope a row under, or no key to seal it under, means nothing
/// safe to write.
class HookCommand extends InjectableCommand {
  @override
  final name = 'hook';

  @override
  final description = "Records one Claude Code hook event's raw payload, for later processing.";

  @override
  bool get requiresAuthentication => false;

  @override
  Future<InjectableCommandResult> runCommand() async {
    final event = argResults?.rest.isEmpty ?? true ? null : argResults!.rest.first;
    final rawPayload = await utf8.decoder.bind(stdin).join();

    await _tryCapture(event: event, rawPayload: rawPayload);

    return const InjectableCommandResult.success();
  }

  /// Attempts to seal and record the exchange text [event] carries, never
  /// letting a missing piece, a malformed payload, or an unreachable piece
  /// of state surface as a failure: this command's contract is to never
  /// fail, whatever the reason.
  Future<void> _tryCapture({required String? event, required String rawPayload}) async {
    try {
      final direction = _directionByEvent[event];
      if (direction == null) return;

      final publicKey = globals.capturePublicKey;
      final session = globals.storedSession;
      if (publicKey == null || session == null) return;

      final payload = jsonDecode(rawPayload) as Map<String, dynamic>;
      final text = payload[_textFieldByDirection[direction]] as String?;
      final exchangeId = payload['prompt_id'] as String?;
      if (text == null || text.isEmpty || exchangeId == null) return;

      final projectId = await globals.projectId;
      final sealed = await seal(plaintext: Uint8List.fromList(utf8.encode(text)), recipientPublicKey: publicKey);

      recordCapture(
        databasePath: globals.capturesDatabasePath,
        projectId: projectId,
        accountHost: session.host.name,
        accountLogin: session.login,
        exchange: CapturedExchange(direction: direction, exchangeId: exchangeId, payload: sealed),
      );
    } catch (_) {
      return;
    }
  }
}
