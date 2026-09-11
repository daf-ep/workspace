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

import 'package:fiber_shell/fiber_shell.dart';

import 'base/common.dart';

const List<String> _supportedHosts = ['github.com', 'gitlab.com'];

/// The id a project's `origin` remote gives it: `host/owner/repo`.
///
/// injectable only works inside a git repository whose `origin` remote is hosted on
/// GitHub or GitLab: that remote is the one thing about a project that stays
/// the same across every machine it gets cloned onto, which a generated id
/// stored in a file never could.
///
/// Throws a [ToolExit] when [directory] isn't inside a git repository, when
/// it has no `origin` remote, or when that remote isn't hosted on GitHub or
/// GitLab.
Future<String> gitProjectId(Directory directory) async {
  final root = await _runGit(Git.repo(directory.path).revParse().showToplevel());
  if (root.failed) {
    throwToolExit('injectable: not a git repository. injectable only works inside one.');
  }

  final remote = await _runGit(Git.repo(directory.path).remote().getUrl().remoteName('origin'));
  if (remote.failed) {
    throwToolExit(
      'injectable: this git repository has no "origin" remote. injectable needs one to identify the project.',
    );
  }

  final location = _parseRemote(remote.text);
  if (location == null || !_supportedHosts.contains(location.host)) {
    final host = location?.host ?? remote.text;
    throwToolExit(
      'injectable: only GitHub and GitLab repositories are supported (${_supportedHosts.join(', ')}), this remote is on $host.',
    );
  }

  return '${location.host}/${location.path}';
}

Future<ShellResult> _runGit(GitCmd command) async {
  try {
    return await command.output();
  } on ProcessException {
    throwToolExit('injectable: git is not installed. Install it, then run this again.');
  }
}

class _RemoteLocation {
  const _RemoteLocation(this.host, this.path);
  final String host;
  final String path;
}

_RemoteLocation? _parseRemote(String url) {
  final scpStyle = RegExp(r'^[^/@\s]+@([^:/\s]+):(.+)$');
  final scpMatch = url.contains('://') ? null : scpStyle.firstMatch(url);

  String host;
  String path;
  if (scpMatch != null) {
    host = scpMatch.group(1)!;
    path = scpMatch.group(2)!;
  } else {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    host = uri.host;
    path = uri.path;
  }

  path = path.replaceFirst(RegExp('^/'), '').replaceFirst(RegExp(r'\.git$'), '');
  if (path.isEmpty) return null;

  return _RemoteLocation(host.toLowerCase(), path.toLowerCase());
}
