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

import 'package:fiber_shell/fiber_shell.dart';

import 'base/common.dart';

const List<String> _supportedHosts = ['github.com', 'gitlab.com'];

/// The id a project's `origin` remote gives it: `host/owner/repo`.
///
/// dpw only works inside a git repository whose `origin` remote is hosted on
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
    throwToolExit('dpw: not a git repository. dpw only works inside one.');
  }

  final remote = await _runGit(Git.repo(directory.path).remote().getUrl().remoteName('origin'));
  if (remote.failed) {
    throwToolExit('dpw: this git repository has no "origin" remote. dpw needs one to identify the project.');
  }

  final location = _parseRemote(remote.text);
  if (location == null || !_supportedHosts.contains(location.host)) {
    final host = location?.host ?? remote.text;
    throwToolExit(
      'dpw: only GitHub and GitLab repositories are supported (${_supportedHosts.join(', ')}), this remote is on $host.',
    );
  }

  return '${location.host}/${location.path}';
}

Future<ShellResult> _runGit(GitCmd command) async {
  try {
    return await command.output();
  } on ProcessException {
    throwToolExit('dpw: git is not installed. Install it, then run this again.');
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
