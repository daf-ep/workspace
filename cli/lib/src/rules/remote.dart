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

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;

/// Where the shared rules corpus is published: the one repository every
/// project's `dpw` checks against for updates.
Uri get _defaultSource => Uri.https('codeload.github.com', '/daf-ep/workspace/tar.gz/refs/heads/main');

/// Fetches the rules corpus from [source] (the public corpus by default),
/// split into its `global/` and `project/` content, keyed the same way
/// [collectRuleContents] and [collectProjectContents] key a local checkout.
///
/// Returns null on any failure: a network error, a non-200 response, or an
/// archive that does not decode. A caller checking for updates in the
/// background has no use for a stack trace, only for whether it got an
/// answer, so this never throws.
Future<({Map<String, String> global, Map<String, String> project})?> fetchRemoteCorpus({
  Uri? source,
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    final response = await http.get(source ?? _defaultSource).timeout(timeout);
    if (response.statusCode != 200) return null;

    final archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(response.bodyBytes));
    final global = <String, String>{};
    final project = <String, String>{};

    for (final file in archive.files) {
      if (!file.isFile) continue;

      // The archive's own top folder is "<repo>-<ref>/", which the corpus
      // itself has no name for, so it is skipped rather than matched.
      final segments = file.name.split('/');
      if (segments.length < 3 || segments[1] != 'rules') continue;
      final corpusPath = segments.sublist(2);
      if (corpusPath.length < 2) continue;

      final content = utf8.decode(file.content as List<int>);
      switch (corpusPath.first) {
        case 'global':
          global[corpusPath.sublist(1).join('/')] = content;
        case 'project':
          project[corpusPath.last] = content;
      }
    }

    if (global.isEmpty) return null;
    return (global: global, project: project);
  } catch (_) {
    return null;
  }
}
