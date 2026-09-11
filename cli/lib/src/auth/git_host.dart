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

/// The git hosts a dpw account can be linked through.
///
/// Both `dpw login` and [gitProjectId]'s own host check name only these two:
/// switching on this enum instead of a raw string means a third host, if
/// one is ever added, is a compiler error everywhere it still needs
/// handling, not a silent gap.
enum GitHost {
  /// github.com.
  github,

  /// gitlab.com, or a self-managed instance dpw's backend points at.
  gitlab;

  /// How this host reads in a sentence: "GitHub", "GitLab".
  String get label => switch (this) {
    GitHost.github => 'GitHub',
    GitHost.gitlab => 'GitLab',
  };

  /// The host named the way it is written on the wire ("github", "gitlab"),
  /// or null when [wireName] names neither.
  static GitHost? parse(String? wireName) => switch (wireName) {
    'github' => GitHost.github,
    'gitlab' => GitHost.gitlab,
    _ => null,
  };
}
