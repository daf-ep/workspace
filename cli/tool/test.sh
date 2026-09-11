#!/usr/bin/env bash
# Copyright (C) 2026 Fiber
#
# This software is licensed under the PolyForm Noncommercial License 1.0.0. A
# copy of it is available at
# https://polyformproject.org/licenses/noncommercial/1.0.0, and in the LICENSE
# file at the root of this repository.
#
# What you may do:
# - Use, study, and modify this software for any noncommercial purpose,
#   including personal use, research, education, and use by a charitable,
#   public research, public safety, health, environmental, or government
#   institution.
# - Distribute copies of it, with or without your changes, for those same
#   noncommercial purposes.
#
# What you may not do:
# - Use this software, or a modified or combined version of it, in a
#   commercial product or service, or for any other commercial purpose.
# - Sublicense it, or transfer your licence to someone else.
#
# What you must do in return:
# - Keep this notice on every file you received it on.
#
# Disclaimer:
# AS FAR AS THE LAW ALLOWS, THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
# OR CONDITION OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
# NON-INFRINGEMENT. IN NO EVENT SHALL FIBER BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING BUT NOT
# LIMITED TO LOSS OF USE, DATA, PROFITS, OR BUSINESS INTERRUPTION) ARISING OUT
# OF OR RELATED TO THESE TERMS OR THE USE OR NATURE OF THE SOFTWARE, UNDER ANY
# KIND OF LEGAL CLAIM.
#
# This header is a summary written for convenience. Where it differs from the
# LICENSE file, the LICENSE file governs.

set -euo pipefail

PACKAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCOPE="test"

say() {
  echo "[$SCOPE] $1"
}

if ! command -v dart >/dev/null 2>&1; then
  echo "[$SCOPE] dart is not on your PATH. Install the Dart SDK, then run this again." >&2
  echo "[$SCOPE]   https://dart.dev/get-dart" >&2
  exit 1
fi

cd "$PACKAGE"

say "resolving dependencies"
dart pub get

say "analysing"
dart analyze

say "checking the formatting"
dart format --output none --set-exit-if-changed lib bin test

say "running the suite"
dart test "$@"

echo ""
say "everything a push has to pass is green."
