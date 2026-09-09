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

library;

import 'dart:io';

import 'base/context.dart';
import 'base/logger.dart';
import 'rules_sync.dart';

/// The context the current zone carries.
AppContext get context => AppContext.current;

Logger? _loggerInstance;

/// Everything this run prints.
Logger get logger => context.get<Logger>() ?? (_loggerInstance ??= StdoutLogger());

/// Where this run's rules directory is, found once and read from the context after that.
///
/// Wrapped rather than looked up through the raw [Directory] type, so a test
/// overriding it never risks colliding with an unrelated one a future
/// override might register.
class RulesSource {
  /// Wraps [directory], the answer [rulesSource] should give for this run.
  const RulesSource(this.directory);

  /// The rules directory this run reads from, or null when none was found.
  final Directory? directory;
}

/// The rules directory this run syncs from, or null when none was found.
Directory? get rulesSource => (context.get<RulesSource>() ?? RulesSource(findRulesSource())).directory;
